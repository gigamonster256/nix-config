{
  packages.wiiu-downloader =
    {
      lib,
      appimageTools,
      fetchurl,
    }:
    let
      version = "2.82";
      pname = "WiiUDownloader";

      src = fetchurl {
        url = "https://github.com/Xpl0itU/WiiUDownloader/releases/download/v${version}/WiiUDownloader-Linux-x86_64.AppImage";
        hash = "sha256-PDXxws6JGRHD3PXSmeU0DTVVDNc0XnIOEY+ZvTAoc38=";
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
}
