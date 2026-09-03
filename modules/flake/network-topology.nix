# Single source of truth for the LAN topology served by oppie.
#
# Declare VLANs once here (name -> id; the id doubles as the 3rd IPv4 octet
# and the hex subnet suffix for IPv6, matching modules/networking/router.nix
# and hosts/oppie/README.md). Declare hosts where they are most relevant by
# setting `network-topology.hosts."<hostname>" = { vlan, suffix, ... }` in
# the host/service file that owns them; everything below is derived:
#
#   - allocations.<host>               { ipv4, ipv6Gua, ipv6Ula, gateway4, fqdn, ... }
#   - routerVlans                      -> router.lanVlans on oppie
#   - zoneText / reverseZones / allZones -> services.nsd on oppie (via dns.nix)
#   - proxyForwards                    -> router.portForwards on oppie (DNAT)
#
# IPv6: ULA (fd45:...) is computed for router internals only. DNS stores
# GUAs (2001:470:b8c5:<vlan-hex>::<suffix>) so records stay stable.
# The suffix is a decimal 2..254 (outside the .100-.199 DHCP pool); the same
# string is appended as the v6 interface id (all-digit strings are valid hex).
{
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.network-topology;
  dns = inputs.dns.lib;

  hex = n: lib.toLower (lib.toHexString n);
  lower = lib.toLower;

  # -- per-VLAN derived networks -------------------------------------------
  vlanIPv4Base = vlan: "172.16.${toString vlan.id}";
  vlanGuaNet = vlan: "${cfg.guaPrefix}:${hex vlan.id}";
  vlanUlaNet = vlan: "${cfg.ulaPrefix}:${hex vlan.id}";

  shortName = lower;
  hostFqdn = name: "${shortName name}.${cfg.domain}";

  # -- allocations ----------------------------------------------------------
  allocations = lib.mapAttrs (
    name: h:
    let
      vlan =
        cfg.vlans.${h.vlan} or (throw "network-topology: host ${name} references unknown vlan ${h.vlan}");
      suffix = toString h.suffix;
    in
    {
      inherit (h) vlan;
      vlanId = vlan.id;
      short = shortName name;
      fqdn = hostFqdn name;
      ipv4 = "${vlanIPv4Base vlan}.${suffix}";
      gateway4 = "${vlanIPv4Base vlan}.1";
      ipv6Gua = "${vlanGuaNet vlan}::${suffix}";
      ipv6Ula = "${vlanUlaNet vlan}::${suffix}";
      inherit (h) aliases;
      inherit (h) proxy;
    }
  ) cfg.hosts;

  allocList = lib.attrValues allocations;

  # -- duplicate / sanity detection (single throw with all errors) ----------
  dupes = xs: lib.filter (x: lib.length (lib.filter (y: y == x) xs) > 1) (lib.unique xs);

  vlanIds = lib.mapAttrsToList (_: v: v.id) cfg.vlans;
  untaggedCount = lib.length (lib.filter (v: v.untagged) (lib.attrValues cfg.vlans));
  allSuffixesPerVlan = lib.mapAttrsToList (_: h: "${h.vlan}/${toString h.suffix}") cfg.hosts;
  allIPv4 = map (a: a.ipv4) allocList;
  allGua = map (a: a.ipv6Gua) allocList;
  hostShorts = map (a: a.short) allocList;
  allAliases = lib.concatMap (a: a.aliases) allocList;
  proxySubs = lib.mapAttrsToList (_: h: lower h.proxy.subdomain) (
    lib.filterAttrs (_: h: h.proxy != null) cfg.hosts
  );
  proxyPorts = lib.mapAttrsToList (_: h: "${h.proxy.protocol}/${toString h.proxy.port}") (
    lib.filterAttrs (_: h: h.proxy != null) cfg.hosts
  );
  reservedSuffixes = lib.filterAttrs (_: h: h.suffix >= 100 && h.suffix <= 199) cfg.hosts;

  errors =
    lib.optional (
      lib.length (lib.unique vlanIds) != lib.length vlanIds
    ) "duplicate vlan ids: ${toString (dupes vlanIds)}"
    ++ lib.optional (untaggedCount > 1) "at most one vlan may set untagged = true"
    ++ lib.optional (
      lib.length (lib.unique allSuffixesPerVlan) != lib.length allSuffixesPerVlan
    ) "duplicate suffix within a vlan: ${toString (dupes allSuffixesPerVlan)}"
    ++ lib.optional (
      lib.length (lib.unique allIPv4) != lib.length allIPv4
    ) "duplicate IPv4 allocations: ${toString (dupes allIPv4)}"
    ++ lib.optional (
      lib.length (lib.unique allGua) != lib.length allGua
    ) "duplicate IPv6 GUA allocations: ${toString (dupes allGua)}"
    ++ lib.optional (
      lib.length (lib.unique allAliases) != lib.length allAliases
    ) "duplicate aliases: ${toString (dupes allAliases)}"
    ++ lib.optional (
      lib.length (lib.filter (a: lib.elem a hostShorts) allAliases) > 0
    ) "alias collides with a hostname: ${toString (lib.filter (a: lib.elem a hostShorts) allAliases)}"
    ++
      lib.optional
        (lib.length (lib.filter (s: lib.elem s (hostShorts ++ allAliases ++ [ "oppie" ])) proxySubs) > 0)
        "proxy subdomain collides with a host/alias: ${
          toString (lib.filter (s: lib.elem s (hostShorts ++ allAliases ++ [ "oppie" ])) proxySubs)
        }"
    ++ lib.optional (
      lib.length (lib.unique proxySubs) != lib.length proxySubs
    ) "duplicate proxy subdomains: ${toString (dupes proxySubs)}"
    ++
      lib.optional (lib.length (lib.unique proxyPorts) != lib.length proxyPorts)
        "duplicate proxy listen ports (one backend per port; use SNI stream proxy for sharing 443): ${toString (dupes proxyPorts)}"
    ++ lib.optional (
      reservedSuffixes != { }
    ) "suffix in DHCP pool range 100-199: ${toString (lib.attrNames reservedSuffixes)}";

  checkedAllocations =
    if errors != [ ] then
      throw "network-topology errors:\n- ${lib.concatStringsSep "\n- " errors}"
    else
      allocations;

  # -- router input ----------------------------------------------------------
  routerVlans = lib.sort (a: b: a.vlanId < b.vlanId) (
    lib.mapAttrsToList (name: v: {
      vlanId = v.id;
      address = "${vlanIPv4Base v}.1/24";
      description = if v.description != "" then v.description else name;
      inherit (v) untagged;
      inherit (v) egressInterface;
    }) cfg.vlans
  );

  gatewayIPv4s = map (v: "${vlanIPv4Base v}.1") (lib.attrValues cfg.vlans);

  # -- forward zone (compiled by dns.nix) ------------------------------------
  baseRecords = {
    SOA = {
      nameServer = "ns1.${cfg.domain}.";
      inherit (cfg) adminEmail;
      inherit (cfg) serial;
    };
    NS = [
      "ns1.${cfg.domain}."
      "ns2.${cfg.domain}."
    ];
  };

  hostSubdomain = name: _h: {
    A = [ checkedAllocations.${name}.ipv4 ];
    AAAA = [ checkedAllocations.${name}.ipv6Gua ];
  };

  forwardSubdomains =
    # oppie (the router) owns .1 on every VLAN; proxies CNAME here
    {
      oppie = {
        A = gatewayIPv4s;
        AAAA = map (v: "${vlanGuaNet v}::1") (lib.attrValues cfg.vlans);
      };
    }
    // lib.mapAttrs' (
      name: h:
      lib.nameValuePair (shortName name) (lib.recursiveUpdate (hostSubdomain name h) h.extraRecords)
    ) cfg.hosts
    // lib.listToAttrs (
      lib.concatMap (
        a: map (alias: lib.nameValuePair (lower alias) { CNAME = [ "${a.fqdn}." ]; }) a.aliases
      ) allocList
    )
    // lib.listToAttrs (
      map (
        name:
        let
          h = cfg.hosts.${name};
        in
        lib.nameValuePair (lower h.proxy.subdomain) { CNAME = [ "oppie.${cfg.domain}." ]; }
      ) (lib.attrNames (lib.filterAttrs (_: h: h.proxy != null) cfg.hosts))
    );

  forwardZone = baseRecords // {
    # apex resolves to the router (handy default target)
    A = gatewayIPv4s;
    AAAA = map (v: "${vlanGuaNet v}::1") (lib.attrValues cfg.vlans);
    subdomains = forwardSubdomains;
  };

  zoneText = dns.toString cfg.domain forwardZone;

  # -- reverse zones ----------------------------------------------------------
  # v4: one /24 zone per vlan; v6: one /64 nibble zone per vlan (GUA only).
  chars = s: lib.genList (i: builtins.substring i 1 s) (builtins.stringLength s);
  revChars = xs: lib.foldl' (acc: x: [ x ] ++ acc) [ ] xs;
  padLeft =
    w: c: s:
    let
      missing = w - builtins.stringLength s;
    in
    (lib.concatStrings (lib.genList (_: c) (if missing > 0 then missing else 0))) + s;
  dottedRevNibbles = s: lib.concatStringsSep "." (revChars (chars s));

  vlanV4RevZone = vlan: "${toString vlan.id}.16.172.in-addr.arpa";
  vlanV6RevZone =
    vlan: "${dottedRevNibbles ("2001" + "0470" + "b8c5" + (padLeft 4 "0" (hex vlan.id)))}.ip6.arpa";
  # last 64 bits are 0000:0000:0000:GGGG where GGGG is the suffix fragment
  suffixNibbles = suffix: "000000000000" + (padLeft 4 "0" suffix);

  # hostKey-attached allocation list for per-VLAN filtering below.
  allocListNamed = lib.mapAttrsToList (hostName: a: a // { hostKey = hostName; }) checkedAllocations;

  # Build reverse zones explicitly (clearer than the combinator above).
  reverseZonesV4 = lib.listToAttrs (
    map (
      vname:
      let
        vlan = cfg.vlans.${vname};
        inVlan = lib.filter (a: a.vlan == vname) allocListNamed;
        subs = lib.listToAttrs (
          map (
            a: lib.nameValuePair (toString cfg.hosts.${a.hostKey}.suffix) { PTR = [ "${a.fqdn}." ]; }
          ) inVlan
        );
      in
      lib.nameValuePair (vlanV4RevZone vlan) (
        dns.toString (vlanV4RevZone vlan) (
          baseRecords
          // {
            subdomains = subs // {
              "1".PTR = [ "oppie.${cfg.domain}." ];
            };
          }
        )
      )
    ) (lib.attrNames cfg.vlans)
  );

  reverseZonesV6 = lib.listToAttrs (
    map (
      vname:
      let
        vlan = cfg.vlans.${vname};
        inVlan = lib.filter (a: a.vlan == vname) allocListNamed;
        subs = lib.listToAttrs (
          map (
            a:
            lib.nameValuePair (dottedRevNibbles (suffixNibbles (toString cfg.hosts.${a.hostKey}.suffix))) {
              PTR = [ "${a.fqdn}." ];
            }
          ) inVlan
        );
        gwLabel = dottedRevNibbles (suffixNibbles "1");
      in
      lib.nameValuePair (vlanV6RevZone vlan) (
        dns.toString (vlanV6RevZone vlan) (
          baseRecords
          // {
            subdomains = subs // {
              ${gwLabel}.PTR = [ "oppie.${cfg.domain}." ];
            };
          }
        )
      )
    ) (lib.attrNames cfg.vlans)
  );

  allZones = {
    ${cfg.domain} = zoneText;
  }
  // reverseZonesV4
  // reverseZonesV6;

  # -- proxy forwards (oppie DNATs these to the owning backend) ---------------
  proxyForwards = lib.mapAttrsToList (name: h: {
    subdomain = lower h.proxy.subdomain;
    fqdn = "${lower h.proxy.subdomain}.${cfg.domain}";
    protocol = h.proxy.protocol;
    port = h.proxy.port;
    targetHost = name;
    targetIP = checkedAllocations.${name}.ipv4;
    targetPort = h.proxy.port;
  }) (lib.filterAttrs (_: h: h.proxy != null) cfg.hosts);
in
{
  options.network-topology = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "lan.nortonweb.org";
      description = "Internal forward zone served authoritatively by oppie (nsd).";
    };
    adminEmail = lib.mkOption {
      type = lib.types.str;
      default = "admin@nortonweb.org";
      description = "SOA contact (real @ address; dns.nix converts it).";
    };
    serial = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "SOA serial. Bump when records change if you ever add secondaries (forwarders don't care).";
    };
    ulaPrefix = lib.mkOption {
      type = lib.types.str;
      default = "fd45:84c0:0f60";
      description = "ULA /48; per-VLAN /64s append :<vlan-hex>. Computed only, never served in DNS.";
    };
    guaPrefix = lib.mkOption {
      type = lib.types.str;
      default = "2001:470:b8c5";
      description = "HE routed /48 base; per-VLAN /64s append :<vlan-hex>. Served as AAAA.";
    };
    vlans = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            id = lib.mkOption {
              type = lib.types.addCheck lib.types.int (x: x >= 1 && x <= 254);
              description = "VLAN id; also the 3rd IPv4 octet and the hex IPv6 subnet suffix.";
            };
            description = lib.mkOption {
              type = lib.types.str;
              default = "";
            };
            untagged = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Native (untagged) LAN on the trunk. At most one.";
            };
            egressInterface = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Egress interface; null = WAN (passed through to router.lanVlans).";
            };
          };
        }
      );
      default = { };
      description = "VLANs by name. IPv4 is 172.16.<id>.0/24 with gateway .1.";
    };
    hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            vlan = lib.mkOption {
              type = lib.types.str;
              description = "Key into network-topology.vlans.";
            };
            suffix = lib.mkOption {
              type = lib.types.addCheck lib.types.int (x: x >= 2 && x <= 254);
              description = "Last IPv4 octet and v6 interface id. Must avoid 100-199 (DHCP pool) and be unique per vlan.";
            };
            aliases = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Extra CNAMEs pointing at this host (e.g. ns1).";
            };
            extraRecords = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "Extra dns.nix records merged into this host's subdomain entry (TXT, MX, ...). Replaces same-type generated records.";
              example = {
                TXT = [ "v=spf1 -all" ];
              };
            };
            proxy = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule {
                  options = {
                    subdomain = lib.mkOption {
                      type = lib.types.str;
                      description = "<subdomain>.lan resolves to oppie, which DNATs <port> to this host.";
                    };
                    port = lib.mkOption {
                      type = lib.types.port;
                      description = "TCP/UDP port forwarded by oppie to this host (same port both ends).";
                    };
                    protocol = lib.mkOption {
                      type = lib.types.enum [
                        "tcp"
                        "udp"
                        "both"
                      ];
                      default = "tcp";
                    };
                  };
                }
              );
              default = null;
            };
          };
        }
      );
      default = { };
      description = "LAN hosts by hostname. Declare each where it is most relevant; merged into DNS.";
    };

    # -- computed (internal) --------------------------------------------------
    allocations = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            vlan = lib.mkOption { type = lib.types.str; };
            vlanId = lib.mkOption { type = lib.types.int; };
            short = lib.mkOption { type = lib.types.str; };
            fqdn = lib.mkOption { type = lib.types.str; };
            ipv4 = lib.mkOption { type = lib.types.str; };
            gateway4 = lib.mkOption { type = lib.types.str; };
            ipv6Gua = lib.mkOption { type = lib.types.str; };
            ipv6Ula = lib.mkOption { type = lib.types.str; };
            aliases = lib.mkOption { type = lib.types.listOf lib.types.str; };
            proxy = lib.mkOption { type = lib.types.anything; };
          };
        }
      );
      description = "Computed per-host addresses (internal).";
    };
    routerVlans = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      description = "Ready to assign to router.lanVlans on oppie (internal).";
    };
    zoneText = lib.mkOption {
      type = lib.types.str;
      description = "Forward zone compiled by dns.nix for services.nsd (internal).";
    };
    reverseZonesV4 = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "IPv4 reverse zones compiled by dns.nix (internal).";
    };
    reverseZonesV6 = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "IPv6 reverse zones compiled by dns.nix (internal).";
    };
    allZones = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "All zones (forward + reverse) for services.nsd.zones (internal).";
    };
    proxyForwards = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      description = "Ready to assign to router.portForwards on oppie (internal).";
    };
  };

  # Seed data as plain (default-priority) config definitions, NOT option
  # `default =`: option defaults are dropped wholesale as soon as any other
  # module defines the same option, while same-priority definitions merge
  # per-key. Each host/vlan leaf must still be defined exactly once across
  # the flake (redefinition errors); the topology error report below catches
  # semantic duplicates (suffix, IP, alias, proxy collisions).
  config.network-topology.vlans = {
    main = {
      id = 12;
      description = "main lan";
      untagged = true;
    };
    vpn = {
      id = 13;
      description = "vpn egress lan";
      egressInterface = "wg-vpn";
    };
    servers = {
      id = 15;
      description = "servers";
    };
    iot = {
      id = 17;
      description = "iot";
    };
  };

  config.network-topology.hosts = {
    # wyse-* hosts declare themselves in hosts/wyse/<name>/default.nix;
    # tinyca keeps its seed here until it gets the same treatment.
    tinyca = {
      vlan = "servers";
      suffix = 20;
    };
  };

  config.network-topology = {
    allocations = checkedAllocations;
    inherit
      routerVlans
      zoneText
      reverseZonesV4
      reverseZonesV6
      allZones
      proxyForwards
      ;
  };
}
