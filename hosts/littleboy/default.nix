# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  modulesPath,
  inputs,
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

    # pretty sure nixos-facter-modules takes care of this
    initrd.availableKernelModules = ["ahci" "xhci_pci" "usb_storage" "sd_mod" "sdhci_pci"];
    initrd.kernelModules = [];
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
  };

  # TODO: stolen from original hardware-configuration.nix not sure if needed
  # networking.useDHCP = lib.mkDefault false; # conflicts with nixos-facter-modules
  networking.interfaces.wlo1.useDHCP = lib.mkDefault true;
  networking.useNetworkd = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

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

  programs.zsh.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true;
  };

  # hardware
  facter.reportPath = ./facter.json;
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
  system.stateVersion = "24.11";
}
