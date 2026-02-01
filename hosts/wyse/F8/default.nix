{ config, ... }:
{
  unify.hosts.nixos.wyse-F8 = {
    modules = with config.unify.modules; [
      wyse
    ];
    nixos =
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];
        services.nginx =
          let
            gcfg = config.services.grafana.settings.server;
          in
          {
            enable = true;
            virtualHosts."${gcfg.domain}" = {
              enableACME = true;
              forceSSL = true;
              locations."/" = {
                proxyPass = "http://${gcfg.http_addr}:${toString gcfg.http_port}";
                proxyWebsockets = true;
                recommendedProxySettings = true;
              };
            };
          };
        services.grafana = {
          enable = true;
          settings = {
            server = {
              # http_addr = "127.0.0.1";
              # http_port = 3000;
              enforce_domain = true;
              enable_gzip = true;
              domain = "grafana.nortonweb.org";
            };

            # Prevents Grafana from phoning home
            analytics.reporting_enabled = false;
          };
          provision = {
            enable = true;

            # Creates a *mutable* dashboard provider, pulling from /etc/grafana-dashboards.
            # With this, you can manually provision dashboards from JSON with `environment.etc` like below.
            dashboards.settings.providers = [
              # {
              #   name = "my dashboards";
              #   disableDeletion = true;
              #   options = {
              #     path = "/etc/grafana-dashboards";
              #     foldersFromFilesStructure = true;
              #   };
              # }
            ];

            datasources.settings.datasources = [
              # Provisioning a built-in data source
              {
                name = "Prometheus";
                type = "prometheus";
                url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
                isDefault = true;
                editable = false;
              }
              # All plugins can be provisioned but it's not always documented: https://github.com/fr-ser/grafana-sqlite-datasource/blob/main/docs/faq.md#can-i-use-provisioning-with-this-plugin
              # Compare below with https://grafana.com/docs/plugins/yesoreyeram-infinity-datasource/latest/setup/provisioning/
              # {
              #   name = "Infinity";
              #   type = "yesoreyeram-infinity-datasource";
              #   editable = false;
              # }
            ];

            # Note: removing attributes from the above `datasources.settings.datasources` is not currently enough for them to be deleted;
            # One needs to use the following option:
            # datasources.settings.deleteDatasources = [ { name = "foo"; orgId = 1; } { name = "bar"; orgId = 1; } ];
          };
        };

        # FIXME: lock down opnsense user privileges
        sops.secrets.opnsense_api_key = { };
        sops.secrets.opnsense_api_secret = { };

        # run the prometheus-opnsense-exporter to monitor the opnsense firewall beyond just node metrics
        # FIXME: harden this service
        # TODO: create a module for this - see pve exporter for example
        systemd.services.prometheus-opnsense-exporter = {
          enable = true;
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          description = "Prometheus OPNsense Exporter";
          # TODO: use environmentFile and sops secret like pve exporter?
          environment = {
            # OPNSENSE_EXPORTER_OPS_API_KEY = "";
            # OPNSENSE_EXPORTER_OPS_API_SECRET = "";
            OPS_API_KEY_FILE = config.sops.secrets.opnsense_api_key.path;
            OPS_API_SECRET_FILE = config.sops.secrets.opnsense_api_secret.path;
          };
          serviceConfig = {
            ExecStart = "${lib.getExe pkgs.prometheus-opnsense-exporter} --opnsense.protocol=https --opnsense.address=opnsense.penguin --exporter.instance-label=opnsense --web.listen-address=[::1]:8080";
          };
        };

        # FIXME: lock down credentials access
        # TODO: use templated secrets with a config file?
        sops.secrets.proxmox_env_file = {
          restartUnits = [ config.systemd.services.prometheus-pve-exporter.name ];
        };

        # run the pve exporter to monitor proxmox hosts
        services.prometheus.exporters.pve = {
          enable = true;
          environmentFile = config.sops.secrets.proxmox_env_file.path;
        };

        # make the python requests library use the system certs
        systemd.services.prometheus-pve-exporter.environment = {
          REQUESTS_CA_BUNDLE = config.security.pki.caBundle;
        };

        # TODO: setup tls/basic auth to scrape hosts and expose frontend through nginx?
        services.prometheus = {
          enable = true;
          retentionTime = "7d";
          globalConfig.scrape_interval = "15s";
          scrapeConfigs = [
            {
              job_name = "node";
              static_configs = [
                {
                  targets =
                    let
                      port = toString config.services.prometheus.exporters.node.port;
                    in
                    # TODO: generate this at the flake level
                    [
                      "localhost:${port}"
                      "wyse-91.penguin:${port}"
                      "wyse-CW.penguin:${port}"
                      "wyse-DX.penguin:${port}"
                      "wyse-F4.penguin:${port}"
                      "opnsense.penguin:9100"
                      "semaphore.penguin:9100"
                    ];
                }
              ];
            }
            {
              job_name = "opnsense";
              static_configs = [
                {
                  targets = [
                    # TODO: pull port from the local prometheus-opnsense-exporter module
                    "localhost:8080"
                  ];
                }
              ];
            }
            {
              job_name = "pve";
              static_configs = [
                {
                  targets = [
                    "semaphore.penguin:8006"
                  ];
                }
              ];
              # scrape local pve exporter by relabelling
              metrics_path = "/pve";
              params = {
                module = [ "default" ];
                # cluster = [ "1" ];
                # node = [ "1" ];
              };
              relabel_configs = [
                {
                  source_labels = [ "__address__" ];
                  target_label = "__param_target";
                }
                {
                  source_labels = [ "__param_target" ];
                  target_label = "instance";
                }
                {
                  target_label = "__address__";
                  replacement = "localhost:${toString config.services.prometheus.exporters.pve.port}"; # the pve exporter's real hostname:port
                }
              ];
            }
          ];
        };
        # dont need node exporter on the prometheus server itself
        services.prometheus.exporters.node.openFirewall = false;
      };
  };

  # TODO: remove when #483459 merged
  nixpkgs.overlays = [
    (final: prev: {
      prometheus-opnsense-exporter = prev.prometheus-opnsense-exporter.overrideAttrs (
        finalAttrs: _prevAttrs: {
          version = "0.0.12";
          src = final.fetchFromGitHub {
            owner = "AthennaMind";
            repo = "opnsense-exporter";
            tag = "v${finalAttrs.version}";
            hash = "sha256-k+o7zvCJypzbBdZQWlTosauvdk1E207H75+fjtE/Ckk=";
          };
        }
      );
    })
  ];
}
