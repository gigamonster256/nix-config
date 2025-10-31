{
  unify.modules.step-ca.nixos =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      services.step-ca = {
        enable = true;
        address = ""; # all interfaces
        port = 443;
        openFirewall = true;
        settings =
          (lib.pipe ./ca.json [
            builtins.readFile
            builtins.fromJSON
          ])
          // {
            db = {
              type = "badgerv2";
              dataSource = "${config.users.users.step-ca.home}/db";
              badgerLoadingFileMode = "";
            };
          };
      };

      environment.systemPackages = with pkgs; [
        # step-cli
        # yubikey-manager
      ];
    };
}
