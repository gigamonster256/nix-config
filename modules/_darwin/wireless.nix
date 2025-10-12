{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  WPAEnterpriseProtocols = [
    "WPAE"
    "WPA2E"
    # Enterprise security is technically supported by
    # networksetup -addpreferredwirelessnetworkatindex
    # but you cannot configure the identity or specify the CA certificate
  ];
in
{
  options = {
    networking.wireless = {
      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/wireless.env";
        description = ''
          File consisting of lines of the form `varname=value`
          to define variables for the wireless configuration.

          Secrets (PSKs, passwords, etc.) can be provided without adding them to
          the world-readable Nix store by defining them in the environment file and
          referring to them in option {option}`networking.wireless.networks`
          with the syntax `@varname@`. Example:

          ```
          # content of /run/secrets/wireless.env
          PSK_HOME=mypassword
          PASS_WORK=myworkpassword
          ```

          ```
          # wireless-related configuration
          networking.wireless.environmentFile = "/run/secrets/wireless.env";
          networking.wireless.networks = {
            home.psk = "@PSK_HOME@";
            work.auth = '''
              eap=PEAP
              identity="my-user@example.com"
              password="@PASS_WORK@"
            ''';
          };
          ```
        '';
      };

      networkService = mkOption {
        type = types.str;
        default = "Wi-Fi";
        description = ''
          The network service name to configure.
          Can be found with `networksetup -listallnetworkservices`.
        '';
      };

      hardwarePort = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The hardware port to configure.
          Takes precedence over {var}`networkService`.
          Can be found with `networksetup -listallhardwareports`.
        '';
      };

      networks = mkOption {
        description = ''
          The network definitions to automatically connect to.
        '';
        default = { };
        example = literalExpression ''
          { echelon = {                   # SSID with no spaces or special characters
              psk = "abcdefgh";           # (password will be written to /nix/store!)
            };

            echelon = {                   # safe version of the above: read PSK from the
              psk = "@PSK_ECHELON@";      # variable PSK_ECHELON, defined in environmentFile,
            };                            # this won't leak into /nix/store

            "echelon's AP" = {            # SSID with spaces and/or special characters
               psk = "ijklmnop";          # (password will be written to /nix/store!)
            };

            "free.wifi" = {};             # Public wireless network
          }
        '';
        type = types.attrsOf (
          types.submodule {
            options = {
              psk = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  The network's pre-shared key in plaintext defaulting
                  to being a network without any authentication.

                  ::: {.warning}
                  Be aware that this will be written to the nix store
                  in plaintext! Use an environment variable instead.
                  :::
                '';
              };

              authProtocol = mkOption {
                default = null;
                type = types.nullOr (
                  types.enum (
                    [
                      "OPEN"

                      "WPA" # supports WPA1/2
                      "WPA2" # supports WPA2/3

                      # "WEP" # WEP is technically supported is extremely insecure
                      # "8021XWEP"
                    ]
                    ++ WPAEnterpriseProtocols
                  )
                );
                description = ''
                  The authentication protocol accepted by this network.
                  This corresponds to the `securitytype` option in
                  networksetup(8) -addpreferredwirelessnetworkatindex.
                '';
              };

              priority = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = ''
                  By default, networks will be prioritized in the order they are declared in the
                  `network` attribute. If some of the networks are more desirable, this field
                  can be used to change the order in which networks will be preferred. The
                  priority groups will be iterated in decreasing priority (i.e., the larger the
                  priority value, the sooner the network is matched against the scan results).
                  Within each priority group, networks will be selected based on security
                  policy, signal strength, etc.
                '';
              };
            };
          }
        );
      };
    };
  };

  config =
    let
      cfg = config.networking.wireless;

      # Networks attrset as a list
      networkList = mapAttrsToList (ssid: opts: opts // { inherit ssid; }) cfg.networks;

      orderedNetworks = flip sort networkList (
        a: b:
        if a.priority == null then
          true
        else if b.priority == null then
          false
        else
          a.priority < b.priority
      );

      mkNetworkSetupCommand =
        {
          ssid,
          psk,
          authProtocol,
          ...
        }:
        let
          quote = s: ''"${s}"'';
          security =
            if psk == null then
              "OPEN" # open network if no psk
            else if authProtocol == null then
              "WPA2" # default WPA2 if psk is provided but no protocol
            else
              authProtocol;
          password = if psk == null then "" else quote psk;
        in
        ''
          networksetup -addpreferredwirelessnetworkatindex $hardwarePort "${ssid}" 0 ${security} ${password}
        '';
    in
    {
      assertions =
        flip mapAttrsToList cfg.networks (
          ssid: cfg: {
            assertion = with cfg; !builtins.elem authProtocol WPAEnterpriseProtocols;
            message = ''${cfg.authProtocol} is not currently supported by darwin-nix. Please open a PR if you would like to see it implemented'';
          }
        )
        ++ flip mapAttrsToList cfg.networks (
          ssid: cfg: {
            assertion = with cfg; psk == null || authProtocol != "OPEN";
            message = ''The open network `networking.wireless."${ssid}"` should not have a psk'';
          }
        );
      system.activationScripts.wireless.text = ''
        echo "configuring wireless..." >&2
        ${optionalString (cfg.environmentFile != null) ''
          source "${cfg.environmentFile}"
        ''}
        ${
          if cfg.hardwarePort != null then
            ''
              hardwarePort=${cfg.hardwarePort}
            ''
          else
            ''
              hardwarePort=$(networksetup -listallhardwareports | ${pkgs.gawk}/bin/awk 'c&&!--c{print $NF};/^Hardware Port: ${cfg.networkService}$/{c=1}')
            ''
        }
        ${concatMapStringsSep "\n" mkNetworkSetupCommand (lists.reverseList orderedNetworks)}
      '';
      # perhaps add some sort of checking in case the networkservice or hardwareport are not found
    };
}
