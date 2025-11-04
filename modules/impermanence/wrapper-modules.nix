{ inputs, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkMerge
    mkIf
    mkAfter
    mkOverride
    ;
in
{
  unify.modules.impermanence = {
    nixos =
      {
        utils,
        config,
        ...
      }:
      let
        cfg = config.impermanence;
      in
      {
        imports = [
          # import nixos impermanence module
          inputs.impermanence.nixosModules.impermanence
          {
            home-manager.sharedModules = [
              # import home-manager impermanence module
              inputs.impermanence.homeManagerModules.impermanence
              # set defaults for impermanence paths (between mkOption and mkDefault)
              {
                impermanence.enable = mkOverride 1250 true;
                impermanence.persistPath = mkOverride 1250 "/persist";
              }
              (
                { config, ... }:
                let
                  cfg = config.impermanence;
                in
                {
                  config = mkIf cfg.enable {
                    home.persistence."${cfg.persistPath}" = {
                      inherit (cfg) directories files;
                    };
                  };
                }
              )
            ];
          }
        ];

        options = {
          impermanence = {
            directories = mkOption {
              type = with types; listOf anything;
              default = [ ];
            };
            files = mkOption {
              type = with types; listOf anything;
              default = [ ];
            };
          };
        };
        config = (
          mkMerge [
            (
              let
                persistPath = "/persist";
                rootFS = config.fileSystems."/";
              in
              {
                assertions = [
                  {
                    # ensure "/persist" is a specified mount
                    assertion = config.fileSystems."${persistPath}".device != null;
                    message = ''"/persist" must be a specified mount to use impermanence'';
                  }
                  {
                    assertion = rootFS.fsType == "btrfs";
                    message = "impermanence requires btrfs filesystem";
                  }
                ];
                # ensure persist path is available at boot
                fileSystems."${persistPath}".neededForBoot = true; # this invalidates the assertion above
                environment.persistence."${persistPath}" = {
                  inherit (cfg) directories files;
                  hideMounts = true;
                };
                boot.initrd.systemd = {
                  # try to resume from hibernation before we go mucking about with the persist subvolume
                  services.create-needed-for-boot-dirs.after = [ "systemd-hibernate-resume.service" ];
                  services.btrfs-wipe = {
                    description = "Prepare btrfs subvolumes for root";
                    wantedBy = [ "initrd-root-device.target" ];
                    after = [
                      "${utils.escapeSystemdPath rootFS.device}.device"
                      "local-fs-pre.target"
                    ];
                    before = [ "sysroot.mount" ];
                    unitConfig.DefaultDependencies = "no";
                    serviceConfig.Type = "oneshot";
                    script =
                      let
                        # parse for "subvol=<subvolume>" option
                        inherit (rootFS) options;
                        subvolOption = builtins.head (
                          builtins.filter (opt: builtins.match "subvol=.*" opt != null) options
                        );
                        subvolName = builtins.match "subvol=(.*)" subvolOption;
                        rootSubvolume = builtins.head subvolName;
                      in
                      # bash
                      ''
                        mount --mkdir ${rootFS.device} /btrfs_tmp
                        if [[ -e /btrfs_tmp/${rootSubvolume} ]]; then
                            mkdir -p /btrfs_tmp/old_roots
                            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/${rootSubvolume})" "+%Y-%m-%-d_%H:%M:%S")
                            mv /btrfs_tmp/${rootSubvolume} "/btrfs_tmp/old_roots/$timestamp"
                        fi

                        # Delete old roots after 30 days
                        for old_root in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
                            btrfs subvolume delete --recursive "$old_root"
                        done

                        # Create new root subvolume
                        btrfs subvolume create /btrfs_tmp/${rootSubvolume}
                        umount /btrfs_tmp
                      '';
                  };
                };
              }
            )
            # some sane defaults for system paths
            {
              impermanence = {
                directories = mkAfter [
                  "/var/log"
                  "/var/lib/nixos"
                  "/var/lib/systemd/coredump"
                  "/var/lib/systemd/timers"
                ];
                files = mkAfter ([
                  "/etc/machine-id"
                  "/etc/ssh/ssh_host_ed25519_key"
                ]);
              };
            }
          ]
        );
      };

    home =
      { config, ... }:
      let
        cfg = config.impermanence;
      in
      {
        options = {
          impermanence = {
            # users can opt in/out of impermanence entirely
            # the nixos module above will default this to true if nixos.impermanence.enable is true
            enable = mkEnableOption "impermanence";
            persistPath = mkOption {
              type = types.singleLineStr;
              default = "/persist";
            };
            directories = mkOption {
              type = with types; listOf anything; # let the impermanence module do the type checking
              default = [ ];
            };
            files = mkOption {
              type = with types; listOf anything; # let the impermanence module do the type checking
              default = [ ];
            };
          };
        };
        # some sane defaults
        config = {
          impermanence = {
            directories = mkAfter [
              ".ssh"
              ".gnupg"
              ".local/share/nix"
            ];
            files = mkAfter [ ];
          };
        };
      };
  };

  # this wrapper for impermanence is imported unconditionally so that
  # programs and home configs can set impermanence options
  # however the actual use of the options only happens in the nixos module above
  # TODO: simplify this? somehow have programs opt into impermanence only if impermanence is enabled?
  unify.home = {
    imports = [
      inputs.self.modules.homeManager.impermanence
    ];
  };
}
