{
  flake.modules.nixos.laptop =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.laptop;
    in
    {
      options.laptop.lidDevice = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };

      config = lib.mkMerge [
        (lib.mkIf
          (
            config.services.fprintd.enable
            && config ? facter
            && config.facter.report.hardware.system.form_factor == "laptop"
          )
          {
            assertions = [
              {
                assertion = cfg.lidDevice != null;
                message = "laptop.lidDevice must be set when fprintd is enabled on a laptop.";
              }
            ];

            # add other services as needed
            # alternative would be to integrate into the pamOpts defaults as a new auth rule
            # to automatically apply to all pam services that don't opt out with useDefaultRules = false
            # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/security/pam.nix
            security.pam.services = lib.genAttrs [ "sudo" ] (
              service:
              let
                fprintRule = config.security.pam.services.${service}.rules.auth.fprintd;
              in
              {
                rules.auth.laptop-lid-closed = {
                  inherit (fprintRule) enable;
                  order = fprintRule.order - 1; # must be right before the fprintd rule
                  control = "[success=1 default=ignore]";
                  modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
                  args = [
                    "quiet"
                    "${pkgs.writeShellScript "laptop-lid-closed" ''
                      ${lib.getExe pkgs.gnugrep} -q closed /proc/acpi/button/lid/${cfg.lidDevice}/state
                    ''}"
                  ];
                };
              }
            );
          }
        )
        {
          services.automatic-timezoned.enable = lib.mkDefault true;
        }
      ];
    };
}
