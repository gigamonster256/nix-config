# https://forge.lel.lol/patrick/nix-config/src/branch/master/modules/ensure-pcr.nix
{
  unify.modules.secure-boot.nixos =
    {
      lib,
      utils,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib)
        head
        optional
        foldl'
        nameValuePair
        listToAttrs
        concatStringsSep
        sortOn
        mkIf
        mkOption
        types
        ;
    in
    {
      options = {
        systemIdentity = {
          pcr15 = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              The expected value of PCR 15 after all luks partitions have been unlocked
              Should be a 64 character hex string as ouput by the sha256 field of
              'systemd-analyze pcrs 15 --json=short'
              If set to null (the default) it will not check the value.
              If the check fails the boot will abort and you will be dropped into an emergency shell, if enabled.
              In emergency shell type:
              'systemctl disable check-pcrs'
              'systemctl default'
              to continue booting
            '';
            example = "6214de8c3d861c4b451acc8c4e24294c95d55bcec516bbf15c077ca3bffb6547";
          };
        };
        boot.initrd.luks.devices = lib.mkOption {
          type =
            with lib.types;
            attrsOf (submodule {
              config.crypttabExtraOpts = [
                "tpm2-device=auto"
                "tpm2-measure-pcr=yes"
              ];
            });
        };
      };
      config = {
        warnings = lib.optional (config.systemIdentity.pcr15 == null) ''
          You have enabled the secure-boot module but have not set systemIdentity.pcr15
          This means the PCR 15 value will not be checked at boot time.
          See https://oddlama.org/blog/bypassing-disk-encryption-with-tpm2-unlock for why this could be bad.
        '';
        assertions = [
          (
            let
              # https://github.com/NixOS/nixpkgs/blob/7e297ddff44a3cc93673bb38d0374df8d0ad73e4/nixos/modules/system/boot/systemd/initrd.nix#L486
              ea = config.boot.initrd.systemd.emergencyAccess;
              access = ea != null && !(lib.isBool ea && !ea);
            in
            {
              assertion = config.systemIdentity.pcr15 == null || access;
              message = ''
                You have set systemIdentity.pcr15 but have not set boot.initrd.systemd.emergencyAccess
                This means if the PCR 15 check fails you will be locked out of your system with no way to recover.
              '';
            }
          )
        ];
        boot.kernelParams = [
          "rd.luks=no"
        ];
        boot.initrd.systemd.extraBin = {
          jq = lib.getExe pkgs.jq;
        };
        boot.initrd.systemd.services = {
          check-pcrs = mkIf (config.systemIdentity.pcr15 != null) {
            script = ''
              echo "Checking PCR 15 value"
              if [[ $(systemd-analyze pcrs 15 --json=short | jq -r ".[0].sha256") != "${config.systemIdentity.pcr15}" ]] ; then
                echo "PCR 15 check failed"
                exit 1
              else
                echo "PCR 15 check succeeded"
              fi
            '';
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            unitConfig.DefaultDependencies = "no";
            after = [ "cryptsetup.target" ];
            before = [ "sysroot.mount" ];
            requiredBy = [ "sysroot.mount" ];
          };
        }
        // (listToAttrs (
          foldl' (
            acc: attrs:
            let
              extraOpts = attrs.value.crypttabExtraOpts ++ (optional attrs.value.allowDiscards "discard");
              cfg = config.boot.initrd.systemd;
            in
            [
              (nameValuePair "cryptsetup-${attrs.name}" {
                unitConfig = {
                  Description = "Cryptography setup for ${attrs.name}";
                  DefaultDependencies = "no";
                  IgnoreOnIsolate = true;
                  Conflicts = [ "umount.target" ];
                  BindsTo = "${utils.escapeSystemdPath attrs.value.device}.device";
                };
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  TimeoutSec = "infinity";
                  KeyringMode = "shared";
                  OOMScoreAdjust = 500;
                  ImportCredential = "cryptsetup.*";
                  ExecStart = "${cfg.package}/bin/systemd-cryptsetup attach '${attrs.name}' '${attrs.value.device}' '-' '${concatStringsSep "," extraOpts}' ";
                  ExecStop = "${cfg.package}/bin/systemd-cryptsetup detach '${attrs.name}' ";
                };
                after = [
                  "cryptsetup-pre.target"
                  "systemd-udevd-kernel.socket"
                  "${utils.escapeSystemdPath attrs.value.device}.device"
                ]
                ++ (optional cfg.tpm2.enable "systemd-tpm2-setup-early.service")
                ++ optional (acc != [ ]) "${(head acc).name}.service";
                before = [
                  "blockdev@dev-mapper-${attrs.name}.target"
                  "cryptsetup.target"
                  "umount.target"
                ];
                wants = [ "blockdev@dev-mapper-${attrs.name}.target" ];
                requiredBy = [ "sysroot.mount" ];
              })
            ]
            ++ acc
          ) [ ] (sortOn (x: x.name) (lib.attrsets.attrsToList config.boot.initrd.luks.devices))
        ));
      };
    };
}
