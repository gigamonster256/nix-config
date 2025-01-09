{
  stdenvNoCC,
  sketchybar,
}:
stdenvNoCC.mkDerivation {
  name = "builtin-sketchybar-plugins";
  inherit (sketchybar) src;
  dontBuild = true;
  patches = [./sketchybar-date.patch];
  installPhase = ''
    runHook preInstall

    cp -r ./plugins $out/

    runHook postInstall
  '';
}
