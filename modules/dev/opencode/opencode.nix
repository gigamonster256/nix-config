{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.opencode.overlays.default
    # (final: _prev: {
    #   opencode = final.opencode2;
    # })
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
      opencodeVersion = lib.getVersion cfg.package;
      isOpencode2 = lib.hasInfix "next" opencodeVersion;
    in
    {
      # custom options for server
      options = {
        programs.opencode.web = {
          port = lib.mkOption {
            type = lib.types.port;
            default =
              if osConfig != null && osConfig ? programs.opencode.port then
                osConfig.programs.opencode.port
              else
                4096;
            readOnly = osConfig != null && osConfig ? programs.opencode.port;
          };
          hostname = lib.mkOption {
            type = lib.types.nullOr lib.types.singleLineStr;
            default = null;
          };
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
            programs.opencode.web.extraArgs = [
              "--port=${toString cfg.web.port}"
            ]
            ++ lib.optional (cfg.web.hostname != null) (
              if isOpencode2 then "--hostname=${cfg.web.hostname}" else "--cors=http://${cfg.web.hostname}"
            );
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

            home.shellAliases = lib.mkIf cfg.enable (
              let
                # opencode vs opencode2
                opencode = cfg.package.meta.mainProgram;
              in
              {
                oc = opencode;
                opencode = lib.mkIf cfg.web.enable (
                  if !isOpencode2 then "${opencode} attach ${url} --dir ." else "${opencode} --server ${url}"
                );
              }
            );

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
        ];
    };

  flake.modules.nixos.opencode =
    { lib, config, ... }:
    {
      # TODO: don't like this option for proxy-dev but need to access the port as set by hm config
      # how to get the value to flow from hm to nixos
      options.programs.opencode.port = lib.mkOption {
        type = lib.types.port;
        default = 4096;
        description = "Port for the opencode web server.";
      };

      config = {
        services.proxy-dev.hosts.opencode = config.programs.opencode.port;
        home-manager.sharedModules = lib.singleton (
          { lib, ... }: {
            # TODO: should this be some sort of services.proxy-dev.hosts.opencode.hostname RO option?
            programs.opencode.web.hostname = lib.mkDefault "opencode.localhost";
          }
        );
      };
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
