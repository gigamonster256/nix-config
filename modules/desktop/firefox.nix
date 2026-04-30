{
  flake.modules.homeManager.desktop =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      programs.firefox = {
        configPath = "${config.xdg.configHome}/mozilla/firefox";
        profiles.default = {
          search = {
            engines =
              let
                nix-icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                paramGen = lib.map (param: lib.foldl' lib.id lib.nameValuePair (lib.splitString "=" param));
              in
              {
                "Nix Packages" = {
                  urls = [
                    {
                      template = "https://search.nixos.org/packages";
                      params = paramGen [
                        "channel=unstable"
                        "query={searchTerms}"
                      ];
                    }
                  ];
                  icon = nix-icon;
                  definedAliases = [ "@np" ];
                };

                "NixOS Modules" = {
                  urls = [
                    {
                      template = "https://search.nixos.org/options";
                      params = paramGen [
                        "channel=unstable"
                        "query={searchTerms}"
                      ];
                    }
                  ];
                  icon = nix-icon;
                  definedAliases = [ "@nm" ];
                };

                "HomeManager Modules" = {
                  urls = [
                    {
                      template = "https://search.nixos.org/options";
                      params = paramGen [
                        "channel=unstable"
                        "query={searchTerms}"
                        "source=home_manager"
                      ];
                    }
                  ];
                  icon = nix-icon;
                  definedAliases = [ "@hm" ];
                };

                "NixOS Wiki" = {
                  urls = [
                    {
                      template = "https://wiki.nixos.org/index.php";
                      params = paramGen [
                        "search={searchTerms}"
                      ];
                    }
                  ];
                  icon = nix-icon;
                  definedAliases = [ "@nw" ];
                };

                "Noogle" = {
                  urls = [
                    {
                      template = "https://noogle.dev/q";
                      params = paramGen [
                        "term={searchTerms}"
                      ];
                    }
                  ];
                  icon = nix-icon;
                  definedAliases = [ "@no" ];
                };

                "Sourcegraph" = {
                  urls = [
                    {
                      template = "https://sourcegraph.com/search";
                      params = paramGen [
                        "q=context:global+{searchTerms}"
                      ];
                    }
                  ];
                  definedAliases = [ "@sg" ];
                };

                bing.metaData.hidden = true;
                ddg.metaData.hidden = true;
                wikipedia.metaData.alias = "@wiki";
                google.metaData.alias = "@g"; # builtin engines only support specifying one additional alias
              };
            force = true; # overwrite config on hm switch
          };
        };
        policies = {
          Preferences = {
            # actually use the userContent.css
            "toolkit.legacyUserProfileCustomizations.stylesheets" = {
              Status = "user";
              Value = true;
            };
          };
        };
      };
    };

  persistence.programs.homeManager = {
    firefox = {
      directories = [
        ".config/mozilla/firefox"
        ".mozilla" # native-messaging-hosts
      ];
    };
  };
}
