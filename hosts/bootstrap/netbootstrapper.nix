{ inputs, ... }:
{
  flake.modules.nixos.netbootstrapper = {
    services.pixiecore =
      let
        bootstrap =
          (inputs.self.nixosConfigurations.bootstrap.extendModules {
            modules = [
              "${inputs.nixpkgs}/nixos/modules/installer/netboot/netboot-minimal.nix"
            ];
          }).config;
        inherit (bootstrap.system) build;
      in
      {
        enable = true;
        openFirewall = true;
        kernel = "${build.kexecTree}/bzImage";
        initrd = "${build.kexecTree}/initrd.gz";
        cmdLine = "init=${build.toplevel}/init ${toString bootstrap.boot.kernelParams}";
      };
  };
}
