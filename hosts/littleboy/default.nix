# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    ./hardware-configuration.nix
  ];

  # Add the rest of your current configuration
  boot.loader = {
    timeout = 0;
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  sops.age = {
    sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    generateKey = false;
  };

  # littleboy cant do WPA3
  networking.wireless.enable = true;
  networking.wireless.fallbackToWPA2 = true;

  # Set your time zone
  time.timeZone = "America/Chicago";

  services.printing.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    catppuccin-sddm
    brightnessctl
  ];

  programs.hyprland.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "catppuccin-mocha";
    # issue with missing sddm-greeter-qt6
    package = pkgs.kdePackages.sddm;
  };

  programs.zsh.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true;
  };

  hardware.graphics = {
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-media-driver
    ];
  };

  # Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    # Replace with your username
    caleb = {
      # You can set an initial password for your user.
      # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      initialPassword = "defaultpassword";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        # Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      # Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
      extraGroups = ["wheel"];
      shell = pkgs.zsh;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
