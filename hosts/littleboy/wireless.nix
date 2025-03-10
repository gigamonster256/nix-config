{config, ...}: {
  sops.secrets.wireless = {
    sopsFile = ../secrets.yaml;
    restartUnits = ["wpa_supplicant.service"];
  };

  networking.wireless = {
    enable = true;
    fallbackToWPA2 = false;
    allowAuxiliaryImperativeNetworks = true;
    secretsFile = config.sops.secrets.wireless.path;
    networks = {
      "Penguin Plaza" = {
        pskRaw = "ext:home_psk";
      };
    };
  };
}
