{pkgs, ...}: {
  imports = [
    ./global

    ./optional/spotify.nix
    ./optional/btop.nix
  ];

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
        ;
    };
  };
}
