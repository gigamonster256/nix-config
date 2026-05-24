{ self, ... }:
{
  configurations.nixos.wyse-DX =
    { pkgs, config, ... }:
    {
      imports = with self.modules.nixos; [
        wyse
        technitium-dns
        backup
      ];
      services.technitium-dns-server.hostName = "ns1.nortonweb.org";
      # TODO: moduleify
      # not using selfhosted CA/ACME since root certs on kobo are embedded and
      # adding my own root seems hard so just let traefik handle it
      services.calibre-web.enable = true;
      services.calibre-web.package = pkgs.calibre-web.overridePythonAttrs (prev: {
        # see nixpkgs drv for more optional deps
        dependencies = prev.dependencies ++ prev.optional-dependencies.kobo;
      });
      services.calibre-web.options.calibreLibrary = "/var/lib/calibre-web/library";
      services.calibre-web.options.enableKepubify = true;
      # docker stack (traefik) is ipv4 only and listening on :: only listens on ipv6 for clibre-web
      services.calibre-web.listen.ip = "0.0.0.0";
      services.calibre-web.openFirewall = true;
    };
}
