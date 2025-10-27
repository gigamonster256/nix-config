{ inputs, config, ... }:
{
  unify.hosts.nixos.chnorton-fw = {
    modules = with config.unify.modules; [
      facter
      disko
      plymouth
      secure-boot
      impermanence
      style
      gaming
      vr
      dev
      desktop
      wireless
      vpn
      laptop
    ];

    users = {
      caleb = {
        # Hmm, not sure if I like this pattern - perhaps auto import unify home modules included in the
        # system modules above?
        modules = with config.unify.modules; [
          style
          dev
          desktop
        ];
      };
    };

    nixos =
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        imports = [
          inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
          inputs.nix-index-database.nixosModules.nix-index
          # home manager
          (
            { config, ... }:
            {
              home-manager = {
                useGlobalPkgs = true;
                # TODO: get rid of this
                extraSpecialArgs = {
                  systemConfig = config;
                };
                sharedModules = [
                  inputs.nix-index-database.homeModules.nix-index
                  inputs.self.modules.homeManager.base
                ];
              };
            }
          )
        ];

        boot = {
          initrd.systemd.emergencyAccess = "$6$5fV/nNXqEFrDtYz7$5.lFDJ3nHnP1Bx9dlEZvZTG2XSO1GFaBb0CV4wT5grM9GrGxGEFVa114shWqlcVu/00WLQWWZiNpAReUb2O4s1";
          binfmt.emulatedSystems = [ "aarch64-linux" ];
        };
        systemIdentity.pcr15 = "f3bdd88e59ccc592f5db3fa3650a60a8a4697b810a6189299b80f14a91695fd3";

        # time zone
        time.timeZone = "America/Chicago";

        # printing
        services.printing.enable = true;

        # docker
        virtualisation.docker.enable = true;

        environment.systemPackages = with pkgs; [
          vim
          git
          brightnessctl
        ];

        programs.zsh.enable = true;

        programs.gnupg.agent = {
          enable = true;
          pinentryPackage = pkgs.pinentry-curses;
          enableSSHSupport = true;
        };

        programs.zoom-us.enable = true;

        programs.wireshark.enable = true;

        sops.secrets.caleb-password = {
          neededForUsers = true;
          sopsFile = ./secrets.yaml;
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
              ];
              shell = pkgs.zsh;
            };
          };
        };

        nixpkgs.hostPlatform = "x86_64-linux";

        # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
        system.stateVersion = "25.11";
      };
  };
}
