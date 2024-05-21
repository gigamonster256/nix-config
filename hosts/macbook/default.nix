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

  programs.zsh.enable = true;

  system.stateVersion = 4;

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.wireless = {
    networks = {
    };
  };
}
