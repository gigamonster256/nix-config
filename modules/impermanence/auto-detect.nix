{ self, lib, ... }:
{
  unify.modules.impermanence.nixos =
    { config, ... }:
    let
      inherit (lib) mkIf mkMerge;
    in
    (mkMerge [
      {
        home-manager.sharedModules = [
          # these programs store data in the home directory
          # but are configured at the system level
          (mkIf config.programs.zoom-us.enable {
            impermanence = {
              directories = [ ".zoom" ];
              files = [
                ".config/zoom.conf"
                ".config/zoomus.conf"
              ];
            };
          })
          (mkIf config.programs.steam.enable {
            impermanence.directories = [
              ".local/share/Steam"
              ".local/share/applications" # save installed game entries - a little crufty
            ];
          })
          (mkIf config.programs.alvr.enable {
            impermanence.directories = [
              ".config/alvr"
              ".config/openvr"
            ];
          })
          (mkIf config.services.gnome.gnome-keyring.enable {
            impermanence.directories = [ ".local/share/keyrings" ];
          })
        ];
      }
      (mkIf config.hardware.bluetooth.enable {
        impermanence.directories = [ "/var/lib/bluetooth" ];
      })
      (mkIf config.services.fprintd.enable {
        impermanence.directories = [ "/var/lib/fprint" ];
      })
      (mkIf (config.boot ? lanzaboote && config.boot.lanzaboote.enable) {
        impermanence.directories = [ config.boot.lanzaboote.pkiBundle ];
      })
    ]);

  unify.modules.impermanence.home =
    { config, ... }:
    let
      inherit (lib) mkIf mkMerge;
      cfg = config.impermanence;
    in
    mkIf cfg.enable (mkMerge [
      (mkIf config.programs.firefox.enable {
        impermanence.directories = [ ".mozilla" ];
      })
      (mkIf config.programs.direnv.enable {
        impermanence.directories = [ ".local/share/direnv" ];
      })
      (mkIf config.programs.zsh.enable {
        impermanence.files = [ ".zsh_history" ];
      })
      # https://github.com/nix-community/home-manager/blob/master/modules/programs/vscode.nix
      # differs based on which vscode fork is used
      (mkIf config.programs.vscode.enable {
        impermanence.directories = [
          ".config/Code"
          ".vscode"
        ];
      })
      (mkIf config.programs.vesktop.enable {
        impermanence.directories = [ ".config/vesktop" ];
      })
      (mkIf config.programs.nix-index-database.comma.enable {
        impermanence.files = [ ".local/state/comma-choices" ];
      })
      (mkIf config.programs.rofi.enable {
        impermanence.files = [ ".cache/rofi3.druncache" ];
      })
      (mkIf config.programs.opencode.enable {
        impermanence.directories = [ ".local/share/opencode" ];
      })
      (mkIf config.programs.gemini-cli.enable {
        impermanence.directories = [ ".gemini" ];
      })
    ]);
}
