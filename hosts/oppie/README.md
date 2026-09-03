# Oppie

NixOS systemd-networkd router, adapted from [apalrd's design](https://www.apalrd.net/posts/2026/asn_networkd/).

CWWK MINIPC-G12, Intel U300, 16GB RAM, 6x Intel I226-V 2.5GbE, 512GB NVMe (Fanxiang S500Pro), UEFI.

## Port map

Interfaces are renamed by MAC via `systemd.network.links` in `default.nix`
(same pattern as chnorton-fw). MACs are sequential on this board, so the
order is deterministic, but **verify which physical port maps to which
name** (plug a cable in and check `ip link` / link LEDs) before cutover.

| name  | MAC               | role                                        |
| ----- | ----------------- | ------------------------------------------- |
| enmg0 | 34:1a:4c:04:10:0d | WAN (DHCPv4 + DHCPv6-PD)                    |
| enmg1 | 34:1a:4c:04:10:0e | LAN hybrid trunk (see below)                |
| enmg2 | 34:1a:4c:04:10:0f | spare                                       |
| enmg3 | 34:1a:4c:04:10:10 | spare                                       |
| enmg4 | 34:1a:4c:04:10:11 | spare                                       |
| enmg5 | 34:1a:4c:04:10:12 | backup (outage mgmt)                        |

## LANs (hybrid trunk on enmg1)

VLAN 12 is the **native/untagged** VLAN on enmg1 (its L3 config lives
directly on the interface); the rest are tagged subinterfaces.
VLAN ids assumed to match the 3rd octet of each subnet.

| VLAN | subnet         | description |
| ---- | -------------- | ----------- |
| 12   | 172.16.12.0/24 | main lan    |
| 13   | 172.16.13.0/24 | vpn egress (TODO: wireguard) |
| 15   | 172.16.15.0/24 | servers (static hosts below 100, DHCP pool .100-.199) |
| 17   | 172.16.17.0/24 | iot         |

- DHCP pool on every LAN: .100 - .199, DNS emitted: ns1/ns2 (172.16.15.50/.51)
- IPv6: ULA `fd45:84c0:0f60::<vlan-hex>::/64` per VLAN + HE `2001:470:b8c5:<vlan-hex>::/64`
  per VLAN (routed /48 below), + DHCPv6-PD SubnetId units (inert without ISP PD)
- VLAN 13 egresses through the `wg-vpn` wireguard interface (nftables + NAT
  rules are already in place), not the WAN
- NAT64 (tayga, `nat64` TUN): prefix `64:ff9b::/96`, v4 pool `192.168.255.0/24`
  (tayga itself `.1`, v6 `fd45:84c0:0f60:64::1`). Pool is masqueraded out the WAN.
  Must match the DNS64 prefix on ns1/ns2.

## Hurricane Electric tunnel (tunnel 925714)

ISP has no IPv6, so `he-6in4` SIT (`modules/networking/router.nix` `router.heTunnel`):

- Server `184.105.253.10`, client `2001:470:1f0e:16c::2/64`, gw `...::1`, MTU 1480
- `Local` intentionally unset: with a dynamic WAN IP the kernel binds the
  outgoing address automatically; HE's side follows via the updater, so no
  tunnel reconfig is needed on IP change
- firewall: proto-41 restricted to the HE server on WAN; LANs forward to `he-6in4`
- updater: `he-tunnel-update.service` + timer (every 5min) polls
  `https://ipv4.tunnelbroker.net/nic/update` (auto-detects IP). Credentials come
  from the `he-tunnel-env` sops template (`HE_USERNAME` = tunnelbroker user,
  `HE_PASSWORD` = tunnel update key if set else account password, `HE_TUNNEL_ID`).
  Currently **disabled** (`credentialsFile = null`) until the sops bootstrap below
  is done.

## Sops bootstrap (needed for the HE updater)

Blocked on two things as of 2026-09-03:

1. PGP subkeys expired 2026-07-17 - extend them first (`gpg --quick-set-expire`,
   needs the YubiKey), otherwise `sops` cannot encrypt.
2. oppie has no age key yet - deploy first, then register it.

Steps:

```bash
# 1. deploy oppie (tunnel works with HE's cached endpoint; updater disabled)
nix run nixpkgs#nixos-anywhere -- --flake .#oppie root@bootstrap.local

# 2. register oppie's host key in .sops.yaml (anchor &oppy + rule already has a
#    pgp-only stub for hosts/oppie/secrets.yaml - add the age recipient there)
ssh-keyscan -t ed25519 <oppie-ip> | ssh-to-age
# or: nix run .#add-sops-host -- <oppie-ip> oppy hosts/oppie/secrets.yaml
#     (then merge the duplicate creation rule it appends into the existing one)

# 3. create secrets and fill in real values
sops hosts/oppie/secrets.yaml
# he:
#   username: <tunnelbroker.net user>
#   password: <tunnel update key (Advanced tab) or account password>

# 4. uncomment the sops block in hosts/oppie/default.nix and set
#    router.heTunnel.credentialsFile = config.sops.templates."he-tunnel-env".path
nixos-rebuild switch --target-host root@oppie.local --flake .#oppie

# 5. verify
systemctl status tayga he-tunnel-update.*
journalctl -u he-tunnel-update
ping -6 2001:470:1f0e:16c::1
```

## DNS (`lan.nortonweb.org`, authoritative on oppie)

Topology lives in `modules/flake/network-topology.nix`: VLAN name + id
(id = 3rd octet, hex IPv6 subnet suffix), hosts declare
`network-topology.hosts."<hostname>" = { vlan, suffix, ... }` in their own
files. Forward + reverse zones are compiled with `dns.nix` and served by
`nsd` (`modules/networking/topology-bindings.nix`, `oppie-dns`).

Technitium ns1/ns2 stay as the DHCP-advertised resolvers; add a conditional
forwarder there for `lan.nortonweb.org` (and the `16.172.in-addr.arpa` /
GUA `ip6.arpa` reverses if wanted) pointing at oppie's LAN IP.

## Deviations from apalrd's post

- `DHCP=ipv4` + `IPv6AcceptRA.DHCPv6Client=always` instead of `DHCP=both`
  (`ForceDHCPv6PDOtherInformation` is deprecated in systemd; `always`
  achieves the same)
- no blanket `iifname $WAN accept` in the input chain (in the post this
  defeats the firewall); WAN input is restricted to established/icmp/dhcp
- otherwise faithful: VLANs + DHCPv6-PD per-LAN, ULA on backup port with
  `RouterLifetimeSec=0`, nftables inet filter + ip nat layout

## TODO

- [ ] sops bootstrap above (unblocks HE endpoint updater)
- [ ] wireguard `wg-vpn` interface (keys via sops) for VLAN 13 egress
- [ ] TCP MSS clamping for the 1480-MTU HE path (and NAT64) if PMTUD proves lossy
- [ ] port forwards: set `network-topology.hosts."<host>".proxy = { subdomain, port }`
  in the host/service file (DNS CNAME + `router.portForwards` DNAT generated;
  see `modules/flake/network-topology.nix`)
- [ ] flowtable offload for 2.5G throughput, if needed

## Deploying

Initial install (facter.json is already generated and cleaned of USB boot
media - do not use `nixify-bootstrap`, it would regenerate it with the
stick attached):

```bash
nix run nixpkgs#nixos-anywhere -- --flake .#oppie root@bootstrap.local
```

Remove the USB stick before reboot, or the box may boot back into the
bootstrap image.

Updates:

```bash
nixos-rebuild switch --target-host root@oppie.local --flake .#oppie
```

Before cutover (old router still owns 172.16.x.1) oppie is reachable via
its backup port as `oppie.local` (ULA + mDNS, v6). Power off the old
router, cable enmg0 to the modem and enmg1 to the switch trunk, and the
networkd units come up as links appear - no reboot needed.
