{
  unify.modules.wireless.nixos =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.networking.wireless;
    in
    {
      sops.secrets.wireless = lib.mkIf cfg.enable {
        sopsFile = ../secrets/secrets.yaml;
        restartUnits = [ "wpa_supplicant.service" ];
        owner = "wpa_supplicant";
      };

      networking.wireless = {
        enable = lib.mkDefault true;
        userControlled = lib.mkDefault true;
        fallbackToWPA2 = lib.mkDefault false;
        allowAuxiliaryImperativeNetworks = lib.mkDefault false;
        secretsFile = config.sops.secrets.wireless.path;
        networks = {
          "Penguin Plaza".pskRaw = "ext:home_psk";
          "Nortfam6".pskRaw = "ext:fam_psk";
          "TAMU_WiFi" = {
            authProtocols = [ "WPA-EAP" ];
            priority = 10;
            auth = ''
              eap=PEAP
              identity="chnorton"
              password=ext:tamu_psk
            '';
          };
          "eduroam" = {
            authProtocols = [ "WPA-EAP" ];
            auth = ''
              eap=PEAP
              identity="chnorton@tamu.edu"
              password=ext:tamu_psk
            '';
          };
          "Caleb's iPhone".pskRaw = "ext:hotspot_psk";
          "Reveille Ranch Resident".pskRaw = "ext:rev_ranch_psk";
          "SpectrumSetup-7E".pskRaw = "ext:gg_psk";
        };
      };
    };
}
