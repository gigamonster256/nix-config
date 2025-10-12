{
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation {
  pname = "waybar-catpuccin-theme";
  version = "1.1";
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    cp -r ./themes $out/
    runHook postInstall
  '';
  src = fetchurl {
    url = "https://github.com/catppuccin/waybar/archive/refs/tags/v1.1.tar.gz";
    sha256 = "RDOMY4dYQ9tlLKv/WCy1T6CV3eZld75hvHT66pMxD8s=";
  };
}
