{ config, ... }:
{
  unify.hosts.nixos.wyse-F4 = {
    modules = with config.unify.modules; [
      wyse
      radicle
      backup
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
      };
  };
}
