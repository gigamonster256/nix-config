let
  wiiu-downloader =
    {
      lib,
      appimageTools,
      fetchurl,
    }:
    let
      version = "2.65";
      pname = "WiiUDownloader";

      src = fetchurl {
        url = "https://github.com/Xpl0itU/WiiUDownloader/releases/download/v${version}/WiiUDownloader-Linux-x86_64.AppImage";
        hash = "sha256-iMs+SrHKUaaeWJT+P42N/F8Yt4HtATswV9mUlidjhl8=";
      };
      appimageContents = appimageTools.extract {
        inherit pname version src;
      };
    in
    appimageTools.wrapType2 rec {
      inherit pname version src;

      extraInstallCommands = ''
        install -m 444 -D ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop
      '';

      meta = {
        description = "Allows to download encrypted wiiu files from nintendo's official servers";
        homepage = "https://github.com/Xpl0itU/WiiUDownloader";
        downloadPage = "https://github.com/Xpl0itU/WiiUDownloader/releases";
        license = lib.licenses.gpl3Only;
        sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
        mainProgram = pname;
        platforms = [ "x86_64-linux" ];
      };
    };
in
{ moduleWithSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.wiiu-downloader = pkgs.callPackage wiiu-downloader { };
    };

  unify.nixos = moduleWithSystem (_: {
    environment.systemPackages = [
      # self'.packages.wiiu-downloader # dont install globally
    ];
  });
}
