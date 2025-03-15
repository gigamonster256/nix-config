{
  config,
  lib,
  ...
}: {
  sops.secrets.wireless = lib.mkIf config.networking.wireless.enable {
    sopsFile = ../secrets.yaml;
    restartUnits = ["wpa_supplicant.service"];
  };

  networking.wireless = {
    userControlled.enable = lib.mkDefault true;
    fallbackToWPA2 = lib.mkDefault false;
    allowAuxiliaryImperativeNetworks = lib.mkDefault false;
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
