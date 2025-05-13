{ lib, pkgs, ... }:
let
  inherit (lib)
    mkDefault
    ;
in
{
  programs.firefox = {
    profiles.default = mkDefault {
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

            "Bing".metaData.hidden = true;
            "DuckDuckGo".metaData.hidden = true;
            "Wikipedia (en)".metaData.alias = "@wiki";
            "Google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
          };
        force = true; # overwrite config on hm switch
      };
    };
  };
}
