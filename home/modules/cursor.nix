{
  lib,
  pkgs,
  options,
  config,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkOption
    mkEnableOption
    types
    any
    ;
  cfg = config.home.pointerCursor;
  opts = options.hacks.pointerCursor;
  hack-cfg = config.hacks.pointerCursor;
in
{
  # bringing in in home-manager options from 25.05
  options = {
    hacks.pointerCursor = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "cursor config generation";
          hyprcursor = {
            enable = mkEnableOption "hyprcursor config generation";

            size = mkOption {
              type = types.nullOr types.int;
              example = 32;
              default = null;
              description = "The cursor size for hyprcursor.";
            };
          };
          dotIcons = {
            enable =
              mkEnableOption ''
                `.icons` config generation for {option}`home.pointerCursor`
              ''
              // {
                default = true;
              };
          };
        };
      };
    };
  };
  config =
    let
      # Check if enable option was explicitly defined by the user
      enableDefined = any (x: x ? enable) opts.definitions;

      # Determine if cursor configuration should be enabled
      enable = if enableDefined then hack-cfg.enable else cfg != null;
    in
    mkMerge [
      {
        home.pointerCursor = mkIf pkgs.stdenv.isLinux {
          # enable = mkDefault config.wayland.windowManager.hyprland.enable;
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 24;
          gtk.enable = true;
          # hyprcursor.enable = true;
        };
        hacks.pointerCursor = {
          enable = mkDefault config.wayland.windowManager.hyprland.enable;
          hyprcursor.enable = true;
        };
      }
      (mkIf enable (mkMerge [
        (mkIf hack-cfg.hyprcursor.enable {
          home.sessionVariables = {
            HYPRCURSOR_THEME = cfg.name;
            HYPRCURSOR_SIZE = if hack-cfg.hyprcursor.size != null then hack-cfg.hyprcursor.size else cfg.size;
          };
        })
        (mkIf hack-cfg.dotIcons.enable {
          # Add symlink of cursor icon directory to $HOME/.icons, needed for
          # backwards compatibility with some applications. See:
          # https://specifications.freedesktop.org/icon-theme-spec/latest/ar01s03.html
          home.file.".icons/default/index.theme".source =
            let
              defaultIndexThemePackage = pkgs.writeTextFile {
                name = "index.theme";
                destination = "/share/icons/default/index.theme";
                # Set name in icons theme, for compatibility with AwesomeWM etc. See:
                # https://github.com/nix-community/home-manager/issues/2081
                # https://wiki.archlinux.org/title/Cursor_themes#XDG_specification
                text = ''
                  [Icon Theme]
                  Name=Default
                  Comment=Default Cursor Theme
                  Inherits=${cfg.name}
                '';
              };
            in
            "${defaultIndexThemePackage}/share/icons/default/index.theme";
          home.file.".icons/${cfg.name}".source = "${cfg.package}/share/icons/${cfg.name}";
        })
      ]))
    ];
}
