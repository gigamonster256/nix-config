{
  flake.modules.nixos.fpga =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    # rules from vivado 2025.2.1
    let
      cfg = config.programs.xilinx;
      rules = pkgs.runCommandLocal "vivado-rules" { } ''
        mkdir -p $out/etc/udev
        cp -r ${./rules} $out/etc/udev/rules.d
      '';
    in
    {
      # FIXME: should installLocation be on root then have impermanence read it?
      # or should location be relative to home dir so persistence can use it?
      options.programs.xilinx.installLocation = lib.mkOption {
        type = lib.types.str;
        default = "/persist/home/caleb/.xilinx";
        description = ''
          The location where Xilinx tools are installed.
        '';
      };

      config = lib.mkMerge [
        {
          programs.xilinx.enable = lib.mkDefault true;
          # some kind of field in persistence.wrappers.nixos entries to not need to do this?
          programs.xilinx.package = null;
        }
        (lib.mkIf cfg.enable {
          services.udev.packages = [ rules ];
          environment.shellAliases = {
            vivado = "${lib.getExe (pkgs.xilinx-env.override { inherit (cfg) installLocation; })} -c vivado";
          };
        })
      ];
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
