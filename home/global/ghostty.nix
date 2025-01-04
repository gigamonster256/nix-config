{
  pkgs,
  lib,
  config,
  ...
}: let
  window-style =
    if pkgs.stdenv.hostPlatform.isLinux
    then "window-decoration = false"
    else "macos-titlebar-style = hidden";
in {
  home.packages = lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.unstable.ghostty;

  home.file."${config.xdg.configHome}/ghostty/config" = {
    text = ''
      # use zsh on path (for nix)
      command = zsh

      theme = catppuccin-mocha
      background-opacity = 0.85

      mouse-hide-while-typing = true
      focus-follows-mouse = true

      ${window-style}

      # use nix-escape-hatch for testing configs
      config-file = ?nix-escape-hatch
    '';
  };
}
