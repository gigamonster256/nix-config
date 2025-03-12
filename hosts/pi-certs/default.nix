{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [./base.nix];

  environment.systemPackages = with pkgs; [vim git yubikey-manager];
  services.pcscd.enable = true;
  services.infnoise.enable = true;
  users = {
    users.myUsername = {
      password = "myPassword";
      isNormalUser = true;
      extraGroups = ["wheel"];
    };
  };
  system.stateVersion = "24.11";
}
