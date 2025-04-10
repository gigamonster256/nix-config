{pkgs, ...}: {
  home = {
    packages = builtins.attrValues {
      inherit
        (pkgs)
        pinentry_mac
        trilium-desktop
        vscode
        net-news-wire
        wireshark
        slack
        element-desktop
        ;
      inherit
        (pkgs.unstable)
        bitwarden-desktop # macos only on unstable
        # bitwarden-cli # broken by https://github.com/NixOS/nixpkgs/pull/390933 on unstable
        ;
    };
  };

  programs.spicetify.enable = true;
  programs.ghostty.enable = true;
  programs.gh.enable = true;
  programs.bat.enable = true;
}
