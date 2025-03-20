{pkgs, ...}: {
  home = {
    packages = builtins.attrValues {
      inherit
        (pkgs)
        pinentry_mac
        trilium-desktop
        vscode
        net-news-wire
        # bitwarden-cli # broken on 24.11 so far
        wireshark
        slack
        element-desktop
        ;
    };
  };

  programs.spicetify.enable = true;
  programs.ghostty.enable = true;
  programs.gh.enable = true;
  programs.eza.enable = true;
  programs.bat.enable = true;
}
