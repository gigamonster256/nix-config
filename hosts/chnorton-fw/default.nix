# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  modulesPath,
  lib,
  pkgs,
  config,
  ...
}:
{
  # not 100% sure if this is needed
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disko.nix
  ];

  # boot config
  boot = {
    # tpm2 luks unlock
    initrd.systemd = {
      enable = true;
      emergencyAccess = "$6$5fV/nNXqEFrDtYz7$5.lFDJ3nHnP1Bx9dlEZvZTG2XSO1GFaBb0CV4wT5grM9GrGxGEFVa114shWqlcVu/00WLQWWZiNpAReUb2O4s1";
    };
    # secure boot
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    loader = {
      timeout = 0;
      systemd-boot.enable = lib.mkForce false; # use lanzaboote
      efi.canTouchEfiVariables = true;
    };
    # binfmt.emulatedSystems = ["aarch64-linux"];
  };

  # extra security https://oddlama.org/blog/bypassing-disk-encryption-with-tpm2-unlock
  systemIdentity = {
    enable = true;
    pcr15 = "f3bdd88e59ccc592f5db3fa3650a60a8a4697b810a6189299b80f14a91695fd3";
  };

  # impermanence
  impermanence = {
    enable = true;
    btrfsWipe = {
      enable = true;
      rootSubvolume = "root";
    };
  };

  # wireless (wpa_supplicant)
  # TODO: use networkmanager
  networking.wireless.enable = true;

  # time zone
  time.timeZone = "America/Chicago";

  # printing
  services.printing.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    catppuccin-sddm
    brightnessctl
  ];

  # hyprland plus sddm login manager
  programs.hyprland.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "catppuccin-mocha";
    # issue with missing sddm-greeter-qt6
    package = pkgs.kdePackages.sddm;
  };
  programs.hyprlock.enable = true;
  services.fprintd.enable = true;

  programs.zsh.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true;
  };

  # hardware
  facter.reportPath = ./facter.json;

  # all the games
  programs.steam.enable = true;

  sops.secrets.caleb-password = {
    neededForUsers = true;
    sopsFile = ./secrets.yaml;
  };

  users = {
    mutableUsers = false;
    users = {
      # Replace with your username
      caleb = {
        hashedPasswordFile = config.sops.secrets.caleb-password.path;
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          # Add your SSH public key(s) here, if you plan on using SSH to connect
        ];
        # Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
      };
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
