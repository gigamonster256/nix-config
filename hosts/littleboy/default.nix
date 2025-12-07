{ config, ... }:
{
  unify.hosts.nixos.littleboy = {
    modules = with config.unify.modules; [
      facter
      disko
      secure-boot
      impermanence
      wireless
      desktop
      style
    ];

    users = {
      caleb = {
        # Hmm, not sure if I like this pattern - perhaps auto import unify home modules included un the
        # system modules above?
        modules = with config.unify.modules; [
          style
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
          # home manager: TODO: remove this
          (
            { config, ... }:
            {
              home-manager = {
                useGlobalPkgs = true;
                # TODO: get rid of this
                extraSpecialArgs = {
                  systemConfig = config;
                };
              };
            }
          )
        ];
        boot = {
          initrd.systemd.emergencyAccess = "$6$5fV/nNXqEFrDtYz7$5.lFDJ3nHnP1Bx9dlEZvZTG2XSO1GFaBb0CV4wT5grM9GrGxGEFVa114shWqlcVu/00WLQWWZiNpAReUb2O4s1";
          # binfmt.emulatedSystems = ["aarch64-linux"];
        };
        systemIdentity.pcr15 = "f3c1ccf9ce465c88851005656454218cccbf4288338a398e6dec035548ceada8";

        # littleboy cant do WPA3
        networking.wireless.fallbackToWPA2 = true;

        environment.systemPackages = with pkgs; [
          vim
          git
        ];

        programs.zsh.enable = true;

        sops.secrets.caleb-password = {
          neededForUsers = true;
          sopsFile = ./secrets.yaml;
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
              extraGroups = [ "wheel" ];
              shell = pkgs.zsh;
            };
          };
        };

        # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
        system.stateVersion = "24.11";

        # router = {
        #   enable = true;
        #   wanInterface = "wlo1";
        #   lanInterface = "enp0s21f0u1u2";
        # };
      };
  };
}
