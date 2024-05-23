{
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
    inputs.nh-darwin.nixDarwinModules.default

    outputs.darwinModules.wireless
    outputs.darwinModules.wireless-activation-script
  ];

  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
  nix.settings.experimental-features = "nix-command flakes";

  environment.systemPackages = with pkgs; [
    gnupg
    pinentry_mac
  ];

  programs.zsh.enable = true;

  programs.nh = {
    enable = true;
    flake = "/Users/caleb/projects/nix-config";
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  networking.hostName = "chnorton-mbp";

  system.stateVersion = 4;

  nixpkgs.hostPlatform = "aarch64-darwin";
}
