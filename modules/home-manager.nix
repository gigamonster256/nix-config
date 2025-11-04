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
        eza.enable = true;
        zsh.enable = true;
        nh.enable = true;
        nix-index-database.comma.enable = true;
        nix-index.enable = true;
      };

      home = {
        packages = builtins.attrValues (
          {
            inherit (pkgs)
              devenv
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
        sessionVariables.EDITOR = "nvim";
        # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
        stateVersion = mkDefault "23.11";
      };

      home.shellAliases = {
        # typos
        nvom = "nvim";
        nivm = "nvim";
        sl = "ls";
        # just open
        open = "xdg-open";
      };

      # Nicely reload system units when changing configs
      systemd.user.startServices = "sd-switch";
    };
}
