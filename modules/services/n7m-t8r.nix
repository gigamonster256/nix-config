{
  flake.modules.nixos.n7m-t8r =
    { pkgs, ... }:
    let
      fqdn = "n7m-t8r.nortonweb.org";
      # skip the redirect if forceSSL
      forceSSL = true;
      VITE_APP_URL = "http${if forceSSL then "s" else ""}://${fqdn}";
      pkg = pkgs.n7m-t8r.overrideAttrs (prevAttrs: {
        env = (prevAttrs.env or { }) // {
          inherit VITE_APP_URL;
        };
      });
    in
    {
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      services.nginx = {
        enable = true;
        virtualHosts.${fqdn} = {
          serverAliases = [ "numeronym.nortonweb.org" ];
          enableACME = true;
          inherit forceSSL;
          locations."/" = {
            root = "${pkg}/share/n7m-t8r";
          };
        };
      };
    };
}
