# Bindings between flake-level network-topology and NixOS.
#
# - nixos.oppie-dns:   serve the dns.nix-compiled zones (forward + reverse)
#   authoritatively with nsd on oppie. Technitium ns1/ns2 stay as the
#   DHCP-advertised LAN resolvers; add a conditional forwarder there for
#   lan.nortonweb.org -> oppie's LAN IP (manual step in the Technitium UI).
# - nixos.oppie-proxy: translate network-topology proxy stanzas into
#   router.portForwards (DNAT on oppie). Each proxied name resolves to
#   oppie via CNAME; the backend keeps its own L7 nginx + ACME.
flake: {
  flake.modules.nixos.oppie-dns =
    { lib, ... }:
    let
      zones = flake.config.network-topology.allZones;
      domain = flake.config.network-topology.domain;
    in
    {
      services.nsd = {
        enable = true;
        # default (no interfaces) = listen on all; reachable from every LAN
        # via the router's input chain once the ports below are opened.
        zones = lib.mapAttrs (_: data: { inherit data; }) zones;
      };

      # nsd on standard DNS ports, reachable from LANs (via the inet
      # filter input chain when the router module is enabled, which it is
      # on oppie).
      router.lanOpenTcpPorts = [ 53 ];
      router.lanOpenUdpPorts = [ 53 ];

      # self-check: compiled zones must pass nsd-checkzone at build time.
      # (nsd's NixOS module already validates zone files during activation.)
      assertions = [
        {
          assertion = zones ? ${domain};
          message = "oppie-dns: forward zone ${domain} missing from network-topology.allZones";
        }
      ];
    };

  flake.modules.nixos.oppie-proxy =
    { lib, ... }:
    let
      forwards = flake.config.network-topology.proxyForwards;
    in
    {
      router.portForwards = map (f: {
        inherit (f) protocol;
        listenPort = f.port;
        inherit (f) targetIP;
        targetPort = f.port;
        description = "${f.fqdn} -> ${f.targetHost} (${f.targetIP})";
      }) forwards;

      assertions = lib.singleton {
        assertion =
          lib.length (lib.unique (map (f: "${f.protocol}/${toString f.port}") forwards))
          == lib.length forwards;
        message = "oppie-proxy: two services share one listen port; give each its own port (or front 443 with an SNI stream proxy)";
      };
    };
}
