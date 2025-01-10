{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  home.packages = let
    ghostty-pkg =
      if pkgs.stdenv.hostPlatform.isLinux
      then pkgs.unstable.ghostty
      else inputs.gigamonster256-nur.packages.${pkgs.stdenv.hostPlatform.system}.ghostty-darwin;
  in [
    ghostty-pkg
  ];

  home.file."${config.xdg.configHome}/ghostty/config" = let
    window-style =
      if pkgs.stdenv.hostPlatform.isLinux
      then "window-decoration = false"
      else "macos-titlebar-style = hidden";
  in {
    text = ''
      # use nix shell
      command = ${lib.getExe config.programs.zsh.package}

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
