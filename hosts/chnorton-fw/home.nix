{
  unify.hosts.nixos.chnorton-fw.nixos = {
    home-manager.users.caleb =
      { pkgs, ... }:
      {
        home.packages = builtins.attrValues {
          inherit (pkgs)
            wpa_supplicant_gui
            # chirp
            # ntop
            ;
          inherit (pkgs.kdePackages)
            okular
            ;
          # inherit (pkgs.python3Packages)
          #   meshtastic
          #   ;
        };

        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "application/pdf" = "org.kde.okular.desktop";
          };
        };

        # amd gpu
        programs.btop.package = pkgs.btop-rocm;

        programs.spotify.enable = true;
        programs.ghostty.enable = true;
        programs.firefox.enable = true;
        programs.trilium.enable = true;
        programs.vesktop.enable = true;
        # programs.bitwarden.enable = true;
        programs.element.enable = true;
        # programs.libreoffice.enable = true;
        # programs.newsflash.enable = true;
        programs.onlyoffice.enable = true;
        # programs.prismlauncher.enable = true;

        # battery is set to charge to 80% max
        # sudo framework_tool --charge-limit
        programs.waybar.settings.mainBar.battery.full-at = 80;

        # disable main screen when lid closed
        wayland.windowManager.hyprland.settings = {
          bindl = [
            ",switch:on:Lid Switch,exec,hyprctl keyword monitor 'desc:BOE,disabled'"
            ",switch:off:Lid Switch,exec,hyprctl keyword monitor 'desc:BOE,preferred,auto,1.566667'"
          ];
        };
      };
  };

  persistence.wrappers.homeManager = [
    {
      name = "trilium";
      packageName = "trilium-next-desktop";
    }
    {
      name = "bitwarden";
      packageName = "bitwarden-desktop";
    }
    {
      name = "element";
      packageName = "element-desktop";
    }
    "newsflash"
    "prismlauncher"
    {
      name = "libreoffice";
      packageName = "libreoffice-fresh";
    }
  ];

  persistence.programs.homeManager = {
    vesktop = {
      directories = [ ".config/vesktop" ];
    };
    trilium = {
      directories = [ ".local/share/trilium-data" ];
    };
    bitwarden = {
      directories = [ ".config/Bitwarden" ];
    };
    element = {
      directories = [ ".config/Element" ];
    };
    newsflash = {
      directories = [
        ".config/news-flash"
        ".local/share/news-flash"
      ];
    };
    prismlauncher = {
      directories = [
        ".local/share/PrismLauncher"
      ];
    };
    libreoffice = {
      directories = [
        ".config/libreoffice"
        # ".local/share/libreoffice"
      ];
    };
  };
}
