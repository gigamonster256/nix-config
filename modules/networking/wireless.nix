{
  flake.modules.nixos.base =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib)
        mkDefault
        mkIf
        ;
      cfg = config.networking.wireless;
    in
    {
      sops.secrets.wireless = mkIf cfg.enable {
        sopsFile = ../secrets/secrets.yaml;
        restartUnits = [ "wpa_supplicant.service" ];
      };

      networking.wireless = {
        userControlled.enable = mkDefault true;
        fallbackToWPA2 = mkDefault false;
        allowAuxiliaryImperativeNetworks = mkDefault false;
        secretsFile = config.sops.secrets.wireless.path;
        networks = {
          "Penguin Plaza".pskRaw = "ext:home_psk";
          "Nortfam6".pskRaw = "ext:fam_psk";
          "TAMU_WiFi" = {
            authProtocols = [ "WPA-EAP" ];
            auth = ''
              eap=PEAP
              identity="chnorton"
              password=ext:tamu_psk
            '';
          };
          "Caleb's iPhone".pskRaw = "ext:hotspot_psk";
          "Reveille Ranch Resident".pskRaw = "ext:rev_ranch_psk";
        };
      };
    };
}
