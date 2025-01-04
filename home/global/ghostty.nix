{
  pkgs,
  lib,
  config,
  ...
}: {
  home.packages = lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.unstable.ghostty;

  home.file."${config.xdg.configHome}/ghostty/config" = {
    text = ''
      # use zsh on path (for nix)
      command = zsh

      theme = catppuccin-mocha
      background-opacity = 0.85

      mouse-hide-while-typing = true

      config-file = ?nix-escape-hatch
    '';
  };
}
