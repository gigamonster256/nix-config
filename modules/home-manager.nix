{ inputs, ... }:
{
  imports = [ inputs.home-manager.flakeModules.home-manager ];
  unify.home =
    {
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkDefault optionalAttrs;
    in
    {
      imports = [ inputs.nix-index-database.homeModules.nix-index ];

      fonts.fontconfig.enable = true;

      programs = {
        direnv = {
          enable = true;
          nix-direnv.enable = true;
          config = {
            global.hide_env_diff = true;
            global.load_dotenv = true;
          };
        };
        btop.enable = true;
        zsh.enable = true;
        nix-index-database.comma.enable = true;
        nix-index.enable = true;
      };

      home = {
        packages = builtins.attrValues (
          {
            inherit (pkgs)
              # devenv # dont need it globally
              magic-wormhole # TODO try out the rust or go version?
              # hyperbeam # pipes via hyperswarm - alternative to magic-wormhole
              ;
          }
          // (optionalAttrs pkgs.stdenv.isLinux {
            inherit (pkgs)
              file
              usbutils
              ;
          })
        );
        # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
        stateVersion = mkDefault "23.11";
      };

      home.shellAliases = {
        sl = "ls";
        # just open
        open = "xdg-open";
      };

      # Nicely reload system units when changing configs
      systemd.user.startServices = "sd-switch";
    };

  persistence.programs.homeManager = {
    direnv = {
      directories = [ ".local/share/direnv" ];
    };
    zsh = {
      files = [ ".zsh_history" ];
    };
    comma = {
      namespace = [
        "programs"
        "nix-index-database"
      ];
      files = [ ".local/state/comma/choices" ];
    };
  };
}
