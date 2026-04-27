{ inputs, ... }:
{
  nixpkgs.overlays = [
    # bring in opencode dev
    # inputs.opencode.overlays.default
    # our nixpkgs bun is too old
    (final: _prev: {
      inherit (inputs.opencode.packages.${final.stdenv.hostPlatform.system}) opencode;
    })
  ];

  flake.modules.homeManager.opencode =
    {
      lib,
      pkgs,
      osConfig,
      config,
      ...
    }:
    let
      cfg = config.programs.opencode;
    in
    {
      options = {
        programs.opencode.web.port = lib.mkOption {
          type = lib.types.port;
          default = 40123;
        };
      };

      config =
        let
          url = "http://localhost:${toString cfg.web.port}";
        in
        lib.mkMerge [
          # actually use custom option
          {
            programs.opencode.web.extraArgs = [ "--port=${toString cfg.web.port}" ];
          }
          {
            programs.opencode = {
              enable = lib.mkDefault true;
              web.enable = lib.mkDefault cfg.enable;
            };

            home.shellAliases = lib.mkIf cfg.enable {
              oc = "opencode";
              opencode = lib.mkIf cfg.web.enable "${lib.getExe cfg.package} attach ${url} --dir .";
            };

            programs.waybar.settings.mainBar = {
              "custom/opencode" =
                let
                  # FIXME: this is duplicated from waybar config, should be refactored
                  # IDEA: write a "trayify" app that wraps an app in a system tray icon?
                  icon = symbol: "<span font_desc='Font Awesome 7 Free'>${symbol}</span>";
                in
                {
                  format = icon "";
                  interval = "once";
                  on-click = "${lib.getExe' pkgs.xdg-utils "xdg-open"} ${url}";
                  tooltip = false;
                };
              # TODO: better ordering
              modules-right = lib.mkBefore [ "custom/opencode" ];
            };
          }
          # tamu providers if this is a nixos config with sops available
          (lib.mkIf (osConfig != null && osConfig ? sops) {
            # patch with tamu finish fix, and settings for both regular and pro tamu ai
            programs.opencode = {
              package = pkgs.opencode.overrideAttrs (
                _finalAttrs: prevAttrs: {
                  patches = (prevAttrs.patches or [ ]) ++ [
                    (pkgs.fetchpatch2 {
                      url = "https://github.com/gigamonster256/opencode/pull/1.patch?full_index=1";
                      hash = "sha256-1idH0VtONIZE3QQK1+UvbQ8tqPKr+mPFrpJO4ZIrfcw=";
                    })
                  ];
                }
              );
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
                source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates."opencode.json".path;
              };
              # install tamu finish hook plugin
              "opencode/plugins/opencode-chat-finish-hook.ts" = {
                source = inputs.opencode-tamu-finish-fix + /src/index.ts;
              };
            };
          })
        ];
    };

  persistence.programs.homeManager = {
    opencode = {
      directories = [
        ".local/share/opencode"
        ".local/state/opencode"
        ".cache/opencode"
      ];
    };
    gemini-cli = {
      directories = [ ".gemini" ];
    };
  };
}
