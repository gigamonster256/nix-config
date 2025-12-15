{ config, ... }:
{
  unify.hosts.nixos.wyse-91 = {
    modules = with config.unify.modules; [
      wyse
    ];
    nixos = {
      services.uptime-kuma.enable = true;
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      services.nginx = {
        enable = true;
        virtualHosts."uptime.nortonweb.org" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3001";
          };
        };
      };
    };
  };
}
