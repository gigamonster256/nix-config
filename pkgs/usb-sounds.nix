let
  myinstant-sound =
    { name, hash }:
    {
      lib,
      fetchurl,
      stdenvNoCC,
      ffmpeg,

      withWav ? true,
    }:
    stdenvNoCC.mkDerivation {
      name = "myinstant-sound-${name}";

      src = fetchurl {
        url = "https://www.myinstants.com/media/sounds/${name}.mp3";
        inherit hash;
      };

      nativeBuildInputs = lib.optional withWav ffmpeg;

      dontUnpack = true;
      dontBuild = true;

      outputs = [
        "out"
      ]
      ++ lib.optional withWav "wav";

      installPhase = ''
        runHook preInstall

        cp $src $out
      ''
      + lib.optionalString withWav ''
        ffmpeg -i $src -f wav $wav
      ''
      + ''
        runHook postInstall
      '';

      meta = {
        license = lib.licenses.unfree;
      };
    };
in
{

  nixpkgs.allowedUnfreePackages = [
    "myinstant-sound-connect"
    "myinstant-sound-disconnect"
    "myinstant-sound-mark-z-windows"
    "myinstant-sound-no-windows"
    "myinstant-sound-halo-shield-recharge-sound"
    "myinstant-sound-alert_shield"
    "myinstant-sound-applepay"
    "myinstant-sound-halo-shield-recharge-sound"
    "myinstant-sound-alert_shield"
  ];

  packages = {
    usb-connect-sound = myinstant-sound {
      name = "connect";
      hash = "sha256-mPAVA51HZ1pokUMK9VVvtFX8QgC4hXhGNrLEaU3Le+4=";
    };
    usb-disconnect-sound = myinstant-sound {
      name = "disconnect";
      hash = "sha256-OComJ5WBJIEgx8oqERsJ5bkYTqQR3GY/SllSCiOmI1M=";
    };
    usb-mark-sound = myinstant-sound {
      name = "mark-z-windows";
      hash = "sha256-i+7RbpUFKywrzr3fdTGooS9Xeovz3FkC2BSbNyMbAFs=";
    };
    usb-no-sound = myinstant-sound {
      name = "no-windows";
      hash = "sha256-QRCzRrKPKfIDlVpl/MvnrkW9DWEi+6H30dIdXR8xlqo=";
    };
    usb-halo-charge-sound = myinstant-sound {
      name = "halo-shield-recharge-sound";
      hash = "sha256-0uhR/oZAiCbq/HRPk6G9qGSBCdsHK8Ab5efDId2ZE2k=";
    };
    usb-halo-deplete-sound = myinstant-sound {
      name = "alert_shield";
      hash = "sha256-XowjT39Xr4moE5xLQcY1uThkI/pqJJj9Sv54dAScsig=";
    };
    applepay-sound = myinstant-sound {
      name = "applepay";
      hash = "sha256-REJexgyWlPeILz11yhZkY8fuRhkoTTK/yHiTaHj5C9s=";
    };
  };

  perSystem =
    { lib, pkgs, ... }:
    let
      allPredicates = preds: x: lib.all (p: p x) preds;
      soundPredicates = [
        # (lib.hasPrefix "usb")
        (lib.hasSuffix "sound")
      ];
      isSoundPackage = name: allPredicates soundPredicates name;
      soundPackages = lib.filterAttrs (name: _: isSoundPackage name) pkgs;
      soundApp =
        soundPkg:
        pkgs.writeShellApplication {
          name = "play-sound";
          runtimeInputs = [ pkgs.mpv ];
          text = "mpv --no-video --volume=100 ${soundPkg.wav}";
        };
    in
    {
      apps = lib.mapAttrs (_name: sound: { program = lib.getExe (soundApp sound); }) soundPackages;
    };
}
