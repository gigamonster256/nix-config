{config, ...}: {
  sops.secrets.wireless = {
    sopsFile = ../secrets.yaml;
    restartUnits = ["wpa_supplicant.service"];
  };

  networking.wireless = {
    enable = true;
    userControlled.enable = true;
    fallbackToWPA2 = false;
    # allowAuxiliaryImperativeNetworks = true;
    secretsFile = config.sops.secrets.wireless.path;
    networks = {
      "Penguin Plaza".pskRaw = "ext:home_psk";
      "TAMU_WiFi" = {
        authProtocols = ["WPA-EAP"];
        auth = ''
          eap=PEAP
          identity="chnorton"
          password=ext:tamu_psk
        '';
      };
    };
  };
}
