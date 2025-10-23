{
  configurations.darwin.chnorton-mbp = {
    home-manager.users.caleb =
      { pkgs, ... }:
      {
        home = {
          packages = builtins.attrValues {
            inherit (pkgs)
              pinentry_mac
              vscode
              net-news-wire
              wireshark
              slack
              element-desktop
              bitwarden-desktop
              trilium-next-desktop
              # bitwarden-cli # broken by https://github.com/NixOS/nixpkgs/pull/390933
              ;
          };
        };

        # programs.spotify.enable = true;
        programs.ghostty.enable = true;

        home.stateVersion = "25.11";
      };
  };
}
