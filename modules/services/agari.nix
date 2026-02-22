{
  unify.modules.agari.nixos =
    { pkgs, ... }:
    {
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      services.nginx = {
        enable = true;
        virtualHosts."agari.nortonweb.org" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            root = pkgs.agari-web;
          };
        };
      };
    };
}
