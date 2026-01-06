{ config, ... }:
{
  unify.hosts.nixos.wyse-F8 = {
    modules = with config.unify.modules; [
      wyse
    ];
    nixos =
      { config, ... }:
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
                    ];
                }
              ];
            }
          ];
        };
        # dont need node exporter on the prometheus server itself
        services.prometheus.exporters.node.openFirewall = false;
      };
  };
}
