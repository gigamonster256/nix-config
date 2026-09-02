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
- IPv6: ULA `fd45:84c0:0f60::<vlan-hex>::/64` per VLAN + DHCPv6-PD from WAN
  (SubnetId = vlan id) when the ISP provides it
- VLAN 13 egresses through the `wg-vpn` wireguard interface (nftables + NAT
  rules are already in place), not the WAN

## Deviations from apalrd's post

- `DHCP=ipv4` + `IPv6AcceptRA.DHCPv6Client=always` instead of `DHCP=both`
  (`ForceDHCPv6PDOtherInformation` is deprecated in systemd; `always`
  achieves the same)
- no blanket `iifname $WAN accept` in the input chain (in the post this
  defeats the firewall); WAN input is restricted to established/icmp/dhcp
- otherwise faithful: VLANs + DHCPv6-PD per-LAN, ULA on backup port with
  `RouterLifetimeSec=0`, nftables inet filter + ip nat layout

## TODO

- [ ] wireguard `wg-vpn` interface (keys via sops) for VLAN 13 egress
- [ ] consider hurricane electric tunnel for v6 if the ISP has no PD
- [ ] port forwards: edit the prerouting chain in `modules/networking/router.nix`
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
