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
    settings = let
      # Monaspace Neon
      font = "Monaspace Neon Var";
      # Monaspace Radon (cursiveish)
      italic-font = "Monaspace Radon Var";
    in
      lib.mkDefault {
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
        font-thicken = true;
        config-file = "?nix-escape-hatch";
        font-feature = [
          "cv01=2" # slashed 0s
        ];
      };
  };
}
