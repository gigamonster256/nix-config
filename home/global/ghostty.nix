{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  programs.ghostty = {
    # TODO: refactor when ghostty makes it into nixpkgs for darwin
    package =
      if pkgs.stdenv.hostPlatform.isLinux
      then pkgs.unstable.ghostty
      else inputs.gigamonster256-nur.packages.${pkgs.stdenv.hostPlatform.system}.ghostty-darwin;
    settings = lib.mkDefault {
      command = "${lib.getExe config.programs.zsh.package}";
      theme = "catppuccin-mocha";
      background-opacity = 0.85;
      mouse-hide-while-typing = true;
      focus-follows-mouse = true;
      window-decoration = false;
      macos-titlebar-style = "hidden";
      config-file = "?nix-escape-hatch";
    };
  };
}
