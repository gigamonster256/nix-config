{
  flake.modules.nixos.fpga =
    { pkgs, ... }:
    # rules from vivado 2025.2.1
    let
      rules = pkgs.runCommandLocal "vivado-rules" { } ''
        mkdir -p $out/etc/udev
        cp -r ${./rules} $out/etc/udev/rules.d
      '';
    in
    {
      services.udev.packages = [ rules ];
      programs.xilinx.enable = true;
      # some kind of field in persistence.wrappers.nixos entries to not need to do this?
      programs.xilinx.package = null;
    };

  persistence.wrappers.nixos = [
    "xilinx"
  ];

  persistence.programs.nixos-home = {
    xilinx = {
      directories = [ ".Xilinx" ];
    };
  };
}
