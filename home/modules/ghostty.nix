{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkForce
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
        {
          command = "${lib.getExe config.programs.zsh.package}";

          # stylix temrinal font selection is too granular
          font-family = mkForce font;
          font-family-italic = mkForce italic-font;
          font-family-bold-italic = mkForce italic-font;
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
