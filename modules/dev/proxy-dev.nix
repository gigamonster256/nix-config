{
  flake.modules.nixos.default =
    { lib, config, ... }:
    let
      cfg = config.services.proxy-dev;
    in
    {
      options.services.proxy-dev = {
        enable = lib.mkEnableOption "development proxy for localhost domain routing";
        addCatchall =
          (lib.mkEnableOption "add catchall nginx virtual host for unmatched .localhost domains")
          // {
            default = true;
          };

        hosts = lib.mkOption {
          type = lib.types.attrsOf lib.types.port;
          default = { };
          example = {
            opencode = 3000;
          };
          description = "Domain names (sans .localhost) mapped to localhost ports.";
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          services.nginx = {
            enable = true;
            virtualHosts = lib.mapAttrs' (
              name: port:
              lib.nameValuePair "${name}.localhost" {
                listen = [
                  {
                    addr = "127.0.0.1";
                    port = 80;
                  }
                ];
                locations."/" = {
                  proxyPass = "http://127.0.0.1:${toString port}";
                  proxyWebsockets = true;
                };
              }
            ) cfg.hosts;
          };
        })
        (lib.mkIf (cfg.enable && cfg.addCatchall) {
          services.nginx.virtualHosts."_" = {
            listen = [
              {
                addr = "127.0.0.1";
                port = 80;
              }
            ];
            locations."/".return = "444";
          };
        })
      ];
    };
}
