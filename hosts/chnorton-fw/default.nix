{ inputs, config, ... }:
{
  # nixpkgs.allowedUnfreePackages = [
  #   "zoom"
  # ];

  # build this host in CI
  ci.x86_64-linux.nixos = [ "chnorton-fw" ];

  unify.hosts.nixos.chnorton-fw = {
    modules = with config.unify.modules; [
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
    ];

    users = {
      caleb = {
        # Hmm, not sure if I like this pattern - perhaps auto import unify home modules included in the
        # system modules above?
        modules = with config.unify.modules; [
          style
          impermanence
          dev
          desktop
          # step-user
          # emulators
          radicle
          crypto
          # niri
          # openclaw
        ];
      };
    };

    nixos =
      {
        pkgs,
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
        ];

        boot = {
          kernelPackages = pkgs.linuxPackages_latest;
          initrd.systemd.emergencyAccess = "$6$5fV/nNXqEFrDtYz7$5.lFDJ3nHnP1Bx9dlEZvZTG2XSO1GFaBb0CV4wT5grM9GrGxGEFVa114shWqlcVu/00WLQWWZiNpAReUb2O4s1";
          binfmt.emulatedSystems = [ "aarch64-linux" ];
        };
        systemIdentity.pcr15 = "00526b01f11a33a1193efc7d8b59d860b7a919dbbfca2f3fe450cc2cff2a80b5";

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

        laptop.lidDevice = "LID0";

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
      };
  };
}
