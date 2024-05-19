{config, ...}: {
  sops.secrets.wireless = {
    sopsFile = ../secrets.yaml;
    restartUnits = ["wpa_supplicant.service"];
  };

  networking.wireless = {
    enable = true;
    fallbackToWPA2 = false;
    environmentFile = config.sops.secrets.wireless.path;
    networks = {
      "@HOME_SSID@" = {
        psk = "@HOME_PSK@";
      };
    };
  };
}
