{
  flake.modules.nixos.agari =
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
            root = "${pkgs.agari-web}/share/agari-web";
          };
        };
      };
    };
}
