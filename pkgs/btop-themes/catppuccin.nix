{
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation {
  pname = "btop-catpuccin-theme";
  version = "1.0.0";
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/btop/themes
    mv ./* $out/share/btop/themes
    runHook postInstall
  '';
  src = fetchurl {
    url = "https://github.com/catppuccin/btop/releases/download/1.0.0/themes.tar.gz";
    sha256 = "UzHgVfI50rQqFUlpBcbzV0k5QOEhPMkaz8umez/XooE=";
  };
}
