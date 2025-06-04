{
  config,
  ...
}:
{
  sops.secrets.openconnect = {
    sopsFile = ../secrets.yaml;
  };

  networking.openconnect.interfaces = {
    TAMU = {
      protocol = "anyconnect";
      gateway = "connect.tamu.edu";
      user = "chnorton";
      passwordFile = config.sops.secrets.openconnect.path;
      autoStart = false;
    };
  };
}
