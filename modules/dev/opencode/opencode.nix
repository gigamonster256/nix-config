{ inputs, ... }:
{
  nixpkgs.overlays = [
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
    let
      cfg = config.programs.opencode;
    in
    {
      options = {
        programs.opencode.web.port = lib.mkOption {
          type = lib.types.port;
          default =
            if osConfig != null && osConfig ? programs.opencode.port then
              osConfig.programs.opencode.port
            else
              40123;
        };
      };

      config =
        let
          proxyDevEnabled =
            osConfig != null && osConfig ? services.proxy-dev.enable && osConfig.services.proxy-dev.enable;
          url =
            if proxyDevEnabled then
              "http://opencode.localhost"
            else
              "http://localhost:${toString cfg.web.port}";
        in
        lib.mkMerge [
          # actually use custom option
          {
            programs.opencode.web.extraArgs = [ "--port=${toString cfg.web.port}" ];
          }
          # project specific tool loading using direnv plugin
          (lib.mkIf config.programs.direnv.enable {
            xdg.configFile."opencode/plugins/opencode-direnv.ts" = {
              source = inputs.opencode-direnv + /src/index.ts;
            };
            # path hack sets PATH to OPENCODE_DIRENV_PATH so we need to add that to the shell PATH if it exists
            programs.zsh.envExtra = ''
              # opencode direnv plugin path hack
              if [ -n "$OPENCODE_DIRENV_PATH" ]; then
                export PATH="$OPENCODE_DIRENV_PATH:$PATH"
              fi
            '';
            # make sure direnv is on opencode's PATH
            programs.opencode.extraPackages = [ config.programs.direnv.package ];
          })
          {
            programs.opencode = {
              enable = lib.mkDefault true;
              web.enable = lib.mkDefault cfg.enable;
            };

            home.shellAliases = lib.mkIf cfg.enable {
              oc = "opencode";
              opencode = lib.mkIf cfg.web.enable "opencode attach ${url} --dir .";
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
                      hash = "sha256-4ir3DBYLuEyH33I7tVvwzoMSQiLOns+6r9gexa3kZR4=";
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

  flake.modules.nixos.opencode =
    { lib, config, ... }:
    {
      options.programs.opencode.port = lib.mkOption {
        type = lib.types.port;
        default = 40123;
        description = "Port for the opencode web server.";
      };

      config.services.proxy-dev.hosts.opencode = config.programs.opencode.port;
    };

  persistence.programs.homeManager = {
    opencode = {
      directories = [
        ".local/share/opencode"
        ".local/state/opencode"
        ".cache/opencode"
      ];
    };
  };
}
