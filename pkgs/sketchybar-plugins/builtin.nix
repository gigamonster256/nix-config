{
  stdenv,
  sketchybar,
}:
stdenv.mkDerivation {
  name = "builtin-sketchybar-plugins";
  inherit (sketchybar) src;
  dontBuild = true;
  patches = [../patches/sketchybar-american-calendar.patch];
  installPhase = ''
    runHook preInstall

    cp -r ./plugins $out/

    runHook postInstall
  '';
}
