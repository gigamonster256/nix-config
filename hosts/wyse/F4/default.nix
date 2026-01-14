{ config, ... }:
{
  unify.hosts.nixos.wyse-F4 = {
    modules = with config.unify.modules; [
      wyse
      radicle
      backup
      bussy
    ];
    nixos =
      { config, ... }:
      {
        sops.secrets.radicle_ssh_key = { };
        services.radicle = {
          settings.node.alias = "rad1.nortonweb.org";
          publicKey = ./radicle_ssh_key.pub;
          privateKeyFile = config.sops.secrets.radicle_ssh_key.path;
        };

        sops.secrets.bussy_vapid_private_key = { };
        services.bussy = {
          openFirewall = true;
          vapidPublicKey = "BK87wS6cEyoLmi8m2jkCGyHTbJq02f95pjSA9C3BwMI3EweApt_8ihtaBMJAKW5--mDsZyDyudD5ziS4z5g-h10";
          vapidPrivateKeyFile = config.sops.secrets.bussy_vapid_private_key.path;
          # listenAddr = "127.0.0.1";
          vapidSubject = "mailto:n0603919@outlook.com";
          mysql.enable = true;
        };

        # services.nginx =
        #   let
        #     bcfg = config.services.bussy;
        #   in
        #   {
        #     enable = true;
        #     virtualHosts."bussy.nortonweb.org" = {
        #       enableACME = true;
        #       forceSSL = true;
        #       locations."/" = {
        #         proxyPass = "http://${bcfg.listenAddr}:${toString bcfg.port}";
        #         proxyWebsockets = true;
        #         recommendedProxySettings = true;
        #       };
        #     };
        #   };
      };
  };
}
