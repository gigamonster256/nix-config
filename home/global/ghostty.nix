{
  home.packages = [
    # pkgs.ghostty
  ];

  home.file."./.config/ghostty/config" = {
    text = ''
      # use zsh on path (for nix)
      command = zsh

      theme = catppuccin-mocha
      background-opacity = 0.85

      mouse-hide-while-typing = true
    '';
  };
}
