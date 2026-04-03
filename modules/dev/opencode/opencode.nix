{ inputs, ... }:
{
  nixpkgs.overlays = [
    # bring in opencode dev
    inputs.opencode.overlays.default
  ];

  flake.modules.homeManager.opencode =
    {
      lib,
      pkgs,
      osConfig,
      config,
      ...
    }:
    lib.mkMerge [
      {
        programs.opencode = {
          enable = lib.mkDefault true;
          web.enable = lib.mkDefault config.programs.opencode.enable;
          # TODO: port option so other modules can reference it?
          web.extraArgs = [
            "--port=40123"
          ];
        };

        home.shellAliases = lib.mkIf config.programs.opencode.enable {
          oc = lib.getExe config.programs.opencode.package;
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
              on-click = "${lib.getExe' pkgs.xdg-utils "xdg-open"} http://127.0.0.1:40123";
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
                  hash = "sha256-gHSJHZNHv6YHDSFVvG8qrXU/GgGDVN6xcYg+RGR4KBw=";
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
