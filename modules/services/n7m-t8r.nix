{
  unify.modules.n7m-t8r.nixos =
    { pkgs, ... }:
    {
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      services.nginx = {
        enable = true;
        virtualHosts."n7m-t8r.nortonweb.org" = {
          serverAliases = [ "numeronym.nortonweb.org" ];
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            root = pkgs.n7m-t8r;
          };
        };
      };
    };
}
