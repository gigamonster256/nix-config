{ inputs, ... }:
{
  flake.modules.homeManager.opencode =
    {
      lib,
      pkgs,
      osConfig,
      config,
      ...
    }:
    let
      cfg = config.programs.opencode.tamu;
    in
    {
      options.programs.opencode.tamu = {
        enable = lib.mkEnableOption "TAMU AI providers for opencode";
      };

      config = lib.mkMerge [
        {
          programs.opencode.tamu.enable = lib.mkDefault (osConfig.programs.opencode.tamu.enable or false);
        }
        (lib.mkIf (cfg.enable && osConfig != null && osConfig ? sops) {
          programs.opencode = {
            package = pkgs.opencode.overrideAttrs (prevAttrs: {
              patches = (prevAttrs.patches or [ ]) ++ [
                (pkgs.fetchpatch2 {
                  url = "https://github.com/gigamonster256/opencode/pull/1.patch?full_index=1";
                  hash = "sha256-4ir3DBYLuEyH33I7tVvwzoMSQiLOns+6r9gexa3kZR4=";
                })
              ];
            });
            settings = {
              provider =
                let
                  # see scripts/update-tamu-models.sh
                  models = lib.importJSON ./tamu-models.json;
                in
                {
                  tamu-ai-pro = {
                    npm = "@ai-sdk/openai-compatible";
                    name = "TAMU Pro Chat";
                    options = {
                      baseURL = "https://pro-chat-api.tamu.ai/api/v1";
                      apiKey = osConfig.sops.placeholder.tamu_pro_ai_key;
                    };
                    inherit models;
                  };
                  tamu-ai = {
                    npm = "@ai-sdk/openai-compatible";
                    name = "TAMU Chat";
                    options = {
                      baseURL = "https://chat-api.tamu.ai/api/v1";
                      apiKey = osConfig.sops.placeholder.tamu_ai_key;
                    };
                    inherit models;
                  };
                };
            };
          };

          xdg.configFile = {
            # override regular generated config file with sops-encrypted template
            "opencode/opencode.json" = lib.mkForce {
              source =
                config.lib.file.mkOutOfStoreSymlink
                  osConfig.sops.templates."opencode-${config.home.username}.json".path;
            };
            # install tamu finish hook plugin
            "opencode/plugins/opencode-chat-finish-hook.ts" = {
              source = inputs.opencode-tamu-finish-fix + /src/index.ts;
            };
          };
        })
      ];
    };

  flake.modules.nixos.opencode =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      tamuUsers = lib.filter (u: config.home-manager.users.${u}.programs.opencode.tamu.enable or false) (
        lib.attrNames config.home-manager.users
      );
    in
    {
      options.programs.opencode.tamu = {
        enable = lib.mkEnableOption "TAMU AI providers for opencode";
      };

      config = lib.mkIf config.programs.opencode.tamu.enable {
        sops.secrets.tamu_ai_key = {
          sopsFile = lib.mkDefault ../../secrets/secrets.yaml;
        };
        sops.secrets.tamu_pro_ai_key = {
          sopsFile = lib.mkDefault ../../secrets/secrets.yaml;
        };

        sops.templates = lib.listToAttrs (
          map (user: {
            name = "opencode-${user}.json";
            value = {
              owner = config.users.users.${user}.name;
              # NOTE: discards MCP server settings and schema - see upstream impl for better handling of this
              file =
                (pkgs.formats.json { }).generate "opencode-${user}.json"
                  config.home-manager.users.${user}.programs.opencode.settings;
            };
          }) tamuUsers
        );
      };
    };
}
