# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  modulesPath,
  lib,
  config,
  pkgs,
  ...
}: {
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
      # TODO: add a password hash for recovery if pcr15 validation fails
      emergencyAccess = false;
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
    # if this changes, 'systemctl disable check-pcrs; systemctl default' in emergency shell to skip check
    pcr15 = "f3c1ccf9ce465c88851005656454218cccbf4288338a398e6dec035548ceada8";
  };

  # impermanence
  impermanence = {
    enable = true;
    btrfsWipe = {
      enable = true;
      rootSubvolume = "root";
    };
  };

  # secrets management
  sops.age = {
    sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    generateKey = false;
  };

  # wireless (wpa_supplicant)
  # TODO: use networkmanager
  networking.wireless.enable = true;
  # littleboy cant do WPA3
  networking.wireless.fallbackToWPA2 = true;

  # time zone
  time.timeZone = "America/Chicago";

  # printing
  # services.printing.enable = true;

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

  programs.zsh.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true;
  };

  # hardware
  facter.reportPath = ./facter.json;

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
  system.stateVersion = "24.11";
}
