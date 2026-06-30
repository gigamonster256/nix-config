{ inputs, ... }:
{
  # ghostty bin on darwin, source build with x11 disabled on linux
  nixpkgs.overlays = [
    (final: prev: {
      ghostty =
        if final.stdenv.hostPlatform.isDarwin then
          final.ghostty-bin
        else
          (
            # disable x11
            (inputs.ghostty.overlays.default final prev).ghostty.override { enableX11 = false; }
          ).overrideAttrs
            # move progress bar to bottom for gtk
            (
              prevAttrs: {
                patches = (prevAttrs.patches or [ ]) ++ [
                  (final.fetchpatch2 {
                    url = "https://github.com/gigamonster256/ghostty/pull/1.patch?full_index=1";
                    hash = "sha256-1gGLg9FSHdvViweoaQh/+aqlOKBwXcc1xavqCFH7POs=";
                  })
                ];
              }
            );
    })
  ];

  # install ghostty terminfo to all hosts with ssh enabled
  flake.modules.nixos.default =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    lib.mkIf config.services.openssh.enable {
      environment.defaultPackages = [ pkgs.ghostty.terminfo ];
    };

  flake.modules.homeManager.default =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.programs.ghostty;
    in
    {
      options = {
        programs.ghostty.openCommand = lib.mkOption {
          type = lib.types.str;
          default = "${lib.getExe cfg.package}${lib.optionalString cfg.systemd.enable " +new-window"}";
          description = "Command to open a new ghostty window.";
          internal = true;
          readOnly = true;
        };
      };
      config = lib.mkMerge [
        {
          programs.ghostty = {
            settings =
              let
                # Monaspace Neon
                font = "Monaspace Neon Var";
                # Monaspace Radon (cursiveish)
                italic-font = "Monaspace Radon Var";
              in
              {
                # stylix terminal font selection is too coarse
                font-family = lib.mkForce font;
                font-family-italic = lib.mkForce italic-font;
                font-family-bold-italic = lib.mkForce italic-font;
                # https://github.com/githubnext/monaspace?tab=readme-ov-file#character-variants
                font-feature = [
                  "cv01=2" # slashed 0s
                  "+cv02" # no bottom serif on 1
                  "+cv31" # 6 pointed asterisk
                ];

                mouse-hide-while-typing = true;
                focus-follows-mouse = true;
                window-decoration = false;
                macos-titlebar-style = "hidden";
                config-file = "?nix-escape-hatch";
                # start new ghostty processes in home
                working-directory = "home";
              }
              # https://ghostty.org/docs/linux/systemd
              // lib.optionalAttrs cfg.systemd.enable {
                quit-after-last-window-closed = false;
              };
          };
        }
        (lib.mkIf cfg.enable {
          fonts.fontconfig.enable = true;
          home.packages = [
            pkgs.monaspace
          ];
        })
      ];
    };
}
