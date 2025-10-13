{ inputs, ... }:
{
  configurations.nixos.tinyca =
    { pkgs, ... }:
    {
      imports = [
        inputs.self.modules.nixos.step-ca
        inputs.nixos-hardware.nixosModules.raspberry-pi-3
      ];

      environment.systemPackages = with pkgs; [
        step-cli
        yubikey-manager
      ];
      services.pcscd.enable = true;
      services.infnoise.enable = true;
      services.openssh.enable = true;
      nixpkgs.hostPlatform = "aarch64-linux";
      system.stateVersion = "24.11";
    };
}
