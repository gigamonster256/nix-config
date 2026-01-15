{ inputs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      bussy = (inputs.bussy.overlays.default final prev).bussy.override {
        # wyse hosts dont have avx support so use baseline build
        bun = prev.bun.overrideAttrs (old: {
          src = final.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v${old.version}/bun-linux-x64-baseline.zip";
            hash = "sha256-a92s1qZYVWmLmBby10hx7aTdC3+pIRQMZEUkj5SnQv0=";
          };
        });
      };
    })
  ];

  unify.nixos =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.services.bussy;
    in
    {
      options = {
        services.bussy = {
          enable = lib.mkEnableOption "bussy service";
          package = lib.mkPackageOption pkgs "bussy" { };
          openFirewall = lib.mkEnableOption "Open firewall for bussy port";

          user = lib.mkOption {
            type = lib.types.str;
            default = "bussy";
            description = "User account under which bussy runs. Also used as the MySQL user when mysql.enable is true.";
          };

          group = lib.mkOption {
            type = lib.types.str;
            default = "bussy";
            description = "Group under which bussy runs.";
          };

          vapidPublicKey = lib.mkOption {
            type = lib.types.str;
            description = "VAPID public key for web push notifications.";
          };

          vapidPrivateKeyFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to file containing VAPID private key.";
          };

          vapidSubject = lib.mkOption {
            type = lib.types.str;
            description = "VAPID subject (usually a mailto: or https: URL).";
          };

          listenAddr = lib.mkOption {
            type = lib.types.str;
            default = "0.0.0.0";
            description = "Address for bussy to listen on.";
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 3000;
            description = "Port for bussy to listen on.";
          };

          mysql = {
            enable = lib.mkEnableOption "mysql database auto-configuration for bussy";

            host = lib.mkOption {
              type = lib.types.str;
              default = "localhost";
              description = "MySQL host for bussy to connect to (used when mysql.enable is false).";
            };

            port = lib.mkOption {
              type = lib.types.port;
              default = 3306;
              description = "MySQL port for bussy to connect to (used when mysql.enable is false).";
            };

            passwordFile = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "Path to file containing MySQL password. Required when mysql.enable is false.";
            };

            database = lib.mkOption {
              type = lib.types.str;
              default = "bussy";
              description = "MySQL database name for bussy to use.";
            };

            socket = lib.mkOption {
              type = lib.types.path;
              default = "/run/mysqld/mysqld.sock";
              description = "Path to MySQL socket for local connections (used when mysql.enable is true).";
            };
          };
        };
      };

      config = lib.mkIf cfg.enable {
        # Assertions
        assertions = [
          {
            assertion = cfg.mysql.enable || cfg.mysql.passwordFile != null;
            message = "services.bussy.mysql.passwordFile is required when services.bussy.mysql.enable is false.";
          }
        ];

        networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

        # Create static user/group when using local MySQL (for socket auth)
        users.users.${cfg.user} = lib.mkIf cfg.mysql.enable {
          isSystemUser = true;
          inherit (cfg) group;
        };

        users.groups.${cfg.group} = lib.mkIf cfg.mysql.enable { };

        # MySQL auto-configuration when mysql.enable = true
        services.mysql = lib.mkIf cfg.mysql.enable {
          enable = true;
          package = lib.mkDefault pkgs.mariadb;
          ensureDatabases = [ cfg.mysql.database ];
          ensureUsers = [
            {
              name = cfg.user;
              ensurePermissions = {
                "${cfg.mysql.database}.*" = "ALL PRIVILEGES";
              };
            }
          ];
        };

        systemd.services.bussy =
          let
            # Socket-based connection for local MySQL (no password needed)
            socketStartScript = pkgs.writeShellScript "bussy-start" ''
              set -euo pipefail

              # Read VAPID private key from credentials
              export VAPID_PRIVATE_KEY="$(cat "$CREDENTIALS_DIRECTORY/vapid-private-key")"

              # Socket-based DATABASE_URL (no password for unix socket auth)
              # mysql2 driver uses socketPath parameter
              export DATABASE_URL="mysql://${cfg.user}@localhost/${cfg.mysql.database}?socketPath=${cfg.mysql.socket}"

              exec ${lib.getExe cfg.package}
            '';

            # Password-based connection for remote MySQL
            passwordStartScript = pkgs.writeShellScript "bussy-start" ''
              set -euo pipefail

              # Read VAPID private key from credentials
              export VAPID_PRIVATE_KEY="$(cat "$CREDENTIALS_DIRECTORY/vapid-private-key")"

              # Read MySQL password and construct DATABASE_URL
              MYSQL_PASSWORD="$(cat "$CREDENTIALS_DIRECTORY/mysql-password")"
              export DATABASE_URL="mysql://${cfg.user}:$MYSQL_PASSWORD@${cfg.mysql.host}:${toString cfg.mysql.port}/${cfg.mysql.database}"

              exec ${lib.getExe cfg.package}
            '';

            startScript = if cfg.mysql.enable then socketStartScript else passwordStartScript;
          in
          {
            description = "Bussy service";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ] ++ lib.optionals cfg.mysql.enable [ "mysql.service" ];
            requires = lib.optionals cfg.mysql.enable [ "mysql.service" ];

            serviceConfig = {
              Type = "simple";
              ExecStart = startScript;

              # User configuration: static user for socket auth, DynamicUser for remote
              DynamicUser = !cfg.mysql.enable;
              User = lib.mkIf cfg.mysql.enable cfg.user;
              Group = lib.mkIf cfg.mysql.enable cfg.group;

              # Load secrets via systemd credentials
              LoadCredential = [
                "vapid-private-key:${cfg.vapidPrivateKeyFile}"
              ]
              ++ lib.optionals (!cfg.mysql.enable) [
                "mysql-password:${cfg.mysql.passwordFile}"
              ];

              # Environment variables
              Environment = [
                "VAPID_PUBLIC_KEY=${cfg.vapidPublicKey}"
                "VAPID_SUBJECT=${cfg.vapidSubject}"
                "LISTEN_ADDR=${cfg.listenAddr}"
                "PORT=${toString cfg.port}"
              ];

              # Hardening
              ProtectSystem = "strict";
              ProtectHome = true;
              PrivateTmp = true;
              NoNewPrivileges = true;
            };
          };
      };
    };
  unify.modules.bussy.nixos =
    { lib, ... }:
    {
      services.bussy.enable = lib.mkDefault true;
    };
}
