{
  pkgs,
  outputs,
  ...
}: {
  imports = [
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

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  system.stateVersion = 4;

  nixpkgs.hostPlatform = "aarch64-darwin";
}
