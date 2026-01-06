{
  unify.modules.node_exporter.nixos =
    { lib, ... }:
    {
      # TODO: tls or basic auth security to only allow my prometheus server to scrape this host
      # other exporters, nginx, node-cert,
      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = lib.mkDefault true;
        port = 9000;
        # For the list of available collectors, run, depending on your install:
        # - Flake-based: nix run nixpkgs#prometheus-node-exporter -- --help
        # - Classic: nix-shell -p prometheus-node-exporter --run "node_exporter --help"
        enabledCollectors = [
          "ethtool"
          "softirqs"
          "systemd"
          "tcpstat"
          "wifi"
        ];
        # You can pass extra options to the exporter using `extraFlags`, e.g.
        # to configure collectors or disable those enabled by default.
        # Enabling a collector is also possible using "--collector.[name]",
        # but is otherwise equivalent to using `enabledCollectors` above.
        extraFlags = [
          "--collector.ntp.protocol-version=4"
          "--no-collector.mdadm"
        ];
      };
    };
}
