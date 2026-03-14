{
  flake.modules.nixos.cyberchef =
    { pkgs, ... }:
    {
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      services.nginx = {
        enable = true;
        virtualHosts."chef.nortonweb.org" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            root = "${pkgs.cyberchef}/share/cyberchef";
          };
        };
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      apps.cyberchef.program = pkgs.writeShellApplication {
        name = "cyberchef";
        runtimeInputs = [ pkgs.python3 ];
        text = "python3 -m http.server --directory ${pkgs.cyberchef}/share/cyberchef --bind 127.0.0.1 8080";
      };
    };
}
