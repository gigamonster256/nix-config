{
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
    outputs.darwinModules.wireless
    outputs.darwinModules.wireless-activation-script

    ../common/global

    # use until https://github.com/LnL7/nix-darwin/pull/942 is merged
    inputs.nh-darwin.nixDarwinModules.prebuiltin
    ../common/optional/nh.nix
  ];

  services.nix-daemon.enable = true;

  environment.systemPackages = with pkgs; [
    gnupg
    pinentry_mac
  ];

  programs.zsh.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  networking.hostName = "chnorton-mbp";

  system.stateVersion = 4;

  nixpkgs.hostPlatform = "aarch64-darwin";
}
