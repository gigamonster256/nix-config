{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    ;
  cfg = config.programs.ghostty;
in
mkMerge [
  {
    programs.ghostty = {
      settings =
        let
          # Monaspace Neon
          font = "Monaspace Neon Var";
          # Monaspace Radon (cursiveish)
          italic-font = "Monaspace Radon Var";
        in
        mkDefault {
          command = "${lib.getExe config.programs.zsh.package}";
          theme = "catppuccin-mocha";
          background-opacity = 0.85;
          mouse-hide-while-typing = true;
          focus-follows-mouse = true;
          window-decoration = false;
          macos-titlebar-style = "hidden";
          font-family = font;
          font-family-italic = italic-font;
          font-family-bold-italic = italic-font;
          config-file = "?nix-escape-hatch";
          # https://github.com/githubnext/monaspace?tab=readme-ov-file#character-variants
          font-feature = [
            "cv01=2" # slashed 0s
            "+cv02" # no bottom serif on 1
            "+cv31" # 6 pointed asterisk
          ];
        };
    };
  }
  (lib.mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    home.packages = [
      pkgs.monaspace
    ];
  })
]
