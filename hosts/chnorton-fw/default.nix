{ inputs, ... }:
{
  # nixpkgs.allowedUnfreePackages = [
  #   "zoom"
  # ];

  # build this host in CI
  flake.ci.x86_64-linux.nixos = [ "chnorton-fw" ];

  configurations.nixos.chnorton-fw =
    {
      lib,
      pkgs,
      options,
      config,
      ...
    }:
    {
      imports = [
        inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
        # inputs.nix-index-database.nixosModules.nix-index
        # is this even needed?
        {
          home-manager = {
            useGlobalPkgs = true;
          };
        }
      ]
      ++ (with inputs.self.modules.nixos; [
        facter
        disko
        plymouth
        secure-boot
        impermanence
        style
        gaming
        # vr
        dev
        desktop
        wireless
        vpn
        laptop
        # step-host
        # no-vts
        crypto
        # niri
        # jj-gpc
        flux-keyboard
      ]);
      config = lib.mkMerge [
        # main config
        {

          home-manager.users.caleb = {
            imports = with inputs.self.modules.homeManager; [
              style
              impermanence
              dev
              desktop
              # step-user
              # emulators
              radicle
              crypto
              # niri
              openclaw
              # jj-gpc
              flux-keyboard
              opencode
            ];
          };

          boot = {
            kernelPackages = pkgs.linuxPackages_latest;
            initrd.systemd.emergencyAccess = "$6$5fV/nNXqEFrDtYz7$5.lFDJ3nHnP1Bx9dlEZvZTG2XSO1GFaBb0CV4wT5grM9GrGxGEFVa114shWqlcVu/00WLQWWZiNpAReUb2O4s1";
            binfmt.emulatedSystems = [ "aarch64-linux" ];
          }
          # TODO: cleaner detection of secure boot - make lanzaboote always imported and add an enable option?
          // lib.optionalAttrs (options.boot ? lanzaboote) {
            systemIdentity.pcr15 = "00526b01f11a33a1193efc7d8b59d860b7a919dbbfca2f3fe450cc2cff2a80b5";
          };

          services.getty.greetingLine = ''<<< chnorton-fw - \l >>>'';

          # virtualisation.docker.enable = true;

          programs.zsh.enable = true;
          # programs.zoom-us.enable = true;
          programs.librepods.enable = false;
          # programs.wireshark.enable = true;

          sops.secrets.caleb-password = {
            neededForUsers = true;
            sopsFile = ./secrets.yaml;
          };

          sops.secrets.syncthing_key = {
            owner = config.users.users.caleb.name;
            inherit (config.users.users.caleb) group;
          };

          users = {
            mutableUsers = false;
            users = {
              # Replace with your username
              caleb = {
                hashedPasswordFile = config.sops.secrets.caleb-password.path;
                isNormalUser = true;
                openssh.authorizedKeys.keys = [
                  # Add your SSH public key(s) here, if you plan on using SSH to connect
                ];
                # Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
                extraGroups = [
                  "wheel"
                  "vpn"
                  "docker"
                  "wireshark"
                  "dialout"
                  "audio"
                  "wpa_supplicant"
                  "librepods"
                ];
                shell = pkgs.zsh;
              };
            };
          };

          services.avahi.enable = true;
          services.avahi.nssmdns6 = true;

          # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
          system.stateVersion = "25.11";

          sops.secrets.radicle_key = {
            owner = config.users.users.caleb.name;
            inherit (config.users.users.caleb) group;
          };

          # FIXME: if renaming an interface, nixos-facter needs to be re-run to update the report with the new name
          # otherwise facter-modules will only generate config for the old name
          systemd.network.links = {
            "10-wlan0" = {
              matchConfig.MACAddress = "d8:b3:2f:bd:bf:c7";
              linkConfig.Name = "wlan0";
            };
            # multi gig ethernet module
            "10-enmg0" = {
              matchConfig.MACAddress = "9c:bf:0d:00:b0:2b";
              linkConfig.Name = "enmg0";
            };
            # home dock
            "10-eng0" = {
              matchConfig.MACAddress = "90:50:c0:80:d3:15";
              linkConfig.Name = "eng0";
            };
          };
        }
        # Testing section - things below here should be modularized and moved to appropriate modules eventually
        {

          environment.systemPackages = [
            pkgs.cifs-utils
          ];

          # predicted PCRs only match when installed uki is exactly the same as the one used to compute them
          # this is not the case when lzbt signs the uki - pcr 7 is different from predicted
          # also pcr4 never seems to exactly match, even when using the same uki - strange
          # pcr7 is correctly predicted though and pcr12 is unused (all 0s)
          # nitro-tpm-pcr-compute has --PK, KEK, db, and dbx options that show promise
          # note: --help notes multiple uki load order?
          system.build.predictedPCRs =
            pkgs.runCommand "predict-pcrs"
              {
                nativeBuildInputs = [
                  pkgs.nitrotpm-tools
                  pkgs.jq
                ];
              }
              ''
                nitro-tpm-pcr-compute --image "${config.system.build.uki}/${config.system.boot.loader.ukiFile}" \
                  | jq -r '
                    .Measurements
                    | to_entries[]
                    | select(.key | startswith("PCR"))
                    | "bottom_turtle:tpm:pcr:\(.key | ltrimstr("PCR")):\(.value)"
                  ' \
                  > $out
              '';

          sops.secrets.tamu_ai_key = {
            sopsFile = ../../modules/secrets/secrets.yaml;
          };
          sops.secrets.tamu_pro_ai_key = {
            sopsFile = ../../modules/secrets/secrets.yaml;
          };
          # FIXME: bring opencode-tamu/sops options into its own module?
          # right now they're pretty intertwined
          sops.templates."opencode.json" =
            let
              cfg = config.home-manager.users.caleb.programs.opencode;
            in
            {
              owner = config.users.users.caleb.name;
              # NOTE: discards MCP server settings and schema - see upstream impl for better handling of this
              file = (pkgs.formats.json { }).generate "opencode.json" cfg.settings;
            };

          # zramSwap = {
          #   enable = true;
          #   algorithm = "zstd";
          #   memoryPercent = 30;
          # };

          boot.zswap.enable = true;

          # TODO: btrbk?
          services.btrfs.autoScrub.enable = true;
        }
      ];
    };
}
