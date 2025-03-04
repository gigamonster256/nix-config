{pkgs, ...}: {
  services.nix-daemon.enable = true;

  security = {pam.enableSudoTouchIdAuth = true;};

  environment.systemPackages = with pkgs; [
    gnupg
    pinentry_mac
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services.sketchybar.enable = true;
  services.aerospace.enable = true;

  users.users = {
    # Replace with your username
    caleb = {
      home = "/Users/caleb";
      shell = pkgs.zsh;
    };
  };

  networking.hostName = "chnorton-mbp";

  system.stateVersion = 4;

  nixpkgs.hostPlatform = "aarch64-darwin";
}
