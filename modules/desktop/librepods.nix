{
  unify.nixos =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options = {
        programs.librepods.enable =
          (lib.mkEnableOption "LibrePods service for managing AirPods connections")
          // {
            inherit (config.hardware.bluetooth) enable;
          };
      };
      config = lib.mkIf config.programs.librepods.enable {
        environment.systemPackages =
          let
            # issues with QT styles causing LibrePods to not launch
            librepods = pkgs.writeShellApplication {
              name = "librepods";

              runtimeInputs = [ pkgs.librepods ];

              text = ''
                unset QT_STYLE_OVERRIDE
                exec librepods
              '';
            };
          in
          [
            librepods
            (pkgs.makeDesktopItem {
              name = "LibrePods";
              exec = lib.getExe librepods;
              # icon = "librepods";
              comment = "AirPods liberated from Apple's ecosystem";
              desktopName = "LibrePods";
              # genericName = "AirPods management utility";
              categories = [
                "Audio"
                "Utility"
              ];
            })
          ];
      };
    };
}
