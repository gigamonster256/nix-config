{
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./base.nix
    ./step-ca
  ];

  environment.systemPackages = with pkgs; [
    step-cli
    yubikey-manager
  ];
  services.pcscd.enable = true;
  services.infnoise.enable = true;
  services.openssh.enable = true;
  system.stateVersion = "24.11";
}
