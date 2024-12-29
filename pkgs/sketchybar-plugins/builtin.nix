{
  stdenv,
  sketchybar,
}:
stdenv.mkDerivation {
  name = "builtin-sketchybar-plugins";
  inherit (sketchybar) src;
  dontBuild = true;
  patches = [../patches/sketchybar-date.patch];
  installPhase = ''
    runHook preInstall

    cp -r ./plugins $out/

    runHook postInstall
  '';
}
