{pkgs, ...}: {
  home = {
    username = "caleb";
    homeDirectory = "/Users/caleb";
    packages = builtins.attrValues {
      inherit
        (pkgs)
        raycast
        pinentry_mac
        trilium-desktop
        # code editing
        vscode
        nil
        net-news-wire
        # bitwarden-cli # broken on 24.11 so far
        wireshark
        slack
        ;
    };
  };

  programs.spicetify.enable = true;
  programs.ghostty.enable = true;

  # TODO: refactor this
  programs.btop.enable = true;
  home.file."./.config/btop/themes" = {
    source = "${pkgs.btop-themes.catppuccin}/share/btop/themes";
  };
}
