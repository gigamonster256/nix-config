{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
{
  programs.firefox = {
    profiles.default = {
      search = {
        engines =
          let
            nix-icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          in
          {
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];

              icon = nix-icon;
              definedAliases = [ "@np" ];
            };

            "NixOS Wiki" = {
              urls = [
                {
                  template = "https://wiki.nixos.org/index.php";
                  params = [
                    {
                      name = "search";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = nix-icon;
              definedAliases = [ "@nw" ];
            };

            "Home Manager" = {
              urls = [
                {
                  template = "https://home-manager-options.extranix.com";
                  params = [
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              definedAliases = [ "@hm" ];
            };

            "Sourcegraph" = {
              urls = [
                {
                  template = "https://sourcegraph.com/search";
                  params = [
                    {
                      name = "q";
                      value = "context:global+{searchTerms}";
                    }
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
      userContent =
        let
          styles = [
            "brave-search"
            "bsky"
            # "chatgpt"
            "cinny"
            "duckduckgo"
            # "github"
            "google"
            # "hacker-news"
            "lobste.rs"
            "nixos-*"
            "npm"
            "ollama"
            "perplexity"
            "reddit"
            "spotify-web"
            # "stack-overflow"
            "whatsapp-web"
            "wikipedia"
            "youtube"
          ];
          # fix this filtering upstream?
          palette = lib.filterAttrs (n: _: lib.hasPrefix "base0" n) config.lib.stylix.colors;
          userStyles = inputs.nix-userstyles.packages.${pkgs.system}.mkUserStyles palette styles;
        in
        builtins.readFile "${userStyles}";
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
}
