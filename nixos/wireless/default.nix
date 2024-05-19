{config, ...}: {
  sops.secrets."wireless.env" = {
    sopsFile = ../../secrets/wireless.env;
    format = "dotenv";
    restartUnits = ["wpa_supplicant.service"];
  };

  networking.wireless = {
    enable = true;
    environmentFile = config.sops.secrets."wireless.env".path;
    networks = {
      "@HOME_SSID@" = {
        psk = "@HOME_PSK@";
      };
    };
  };
}
