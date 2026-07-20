flake: {
  nixpkgs.overlays = [
    (_final: prev: {
      nh-unwrapped = prev.nh-unwrapped.overrideAttrs (old: {
        patches = old.patches or [ ];
      });
    })
  ];

  flake.modules.homeManager.default =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.programs.nh;
    in
    {
      options.programs.nh.autoUpgrade = {
        enable = lib.mkEnableOption "nh home autoUpgrade";
        frequency = lib.mkOption {
          type = lib.types.str;
          example = "weekly";
          default = "daily";
          description = ''
            The interval at which the NH Home Manager auto upgrade is run.
            This value is passed to the systemd timer configuration
            as the `OnCalendar` option.
            The format is described in {manpage}`systemd.time(7)`.
          '';
        };
        flags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "--no-nom"
            "--no-build-output"
          ];
          description = ''
            Options given to nh switch when the service is run automatically.

            See `nh home switch --help` for more information.
          '';
        };
      };
      config = lib.mkMerge [
        (lib.mkIf (cfg.enable && cfg.autoUpgrade.enable) {
          systemd.user = {
            timers.nh-home-manager-auto-upgrade = {
              Unit.Description = "NH Home Manager upgrade timer";

              Install.WantedBy = [ "timers.target" ];

              Timer = {
                OnCalendar = cfg.autoUpgrade.frequency;
                Unit = "nh-home-manager-auto-upgrade.service";
                Persistent = true;
              };
            };

            services.nh-home-manager-auto-upgrade =
              let
                upgradeScript = pkgs.writeShellApplication {
                  name = "nh-home-manager-auto-upgrade";
                  runtimeInputs = [
                    cfg.package
                    config.nix.package
                  ];
                  text = ''
                    exec nh home switch ${lib.escapeShellArgs cfg.autoUpgrade.flags}
                  '';
                };
              in
              {
                Unit = {
                  Description = "NH Home Manager upgrade";
                };

                Service = {
                  ExecStart = lib.getExe upgradeScript;

                  Environment =
                    # backwards compatable old nh?
                    lib.optional (cfg.flake != null) "NH_FLAKE=${cfg.flake}"
                    ++ lib.optional (cfg.homeFlake != null) "NH_HOME_FLAKE=${cfg.homeFlake}";
                };
              };
          };
        })
        {
          programs.nh = {
            enable = lib.mkDefault true;
            flake = lib.mkDefault flake.config.meta.flake;
          };
        }
      ];
    };
}
