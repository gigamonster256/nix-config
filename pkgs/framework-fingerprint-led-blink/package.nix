{
  packages.framework-fingerprint-led-blink =
    {
      lib,
      stdenvNoCC,
      writers,
      dbus,
      makeWrapper,
    }:
    let
      version = "1.0.0";

      script = writers.writePython3Bin "framework-fingerprint-led-blink" { } (
        builtins.readFile ./framework-fingerprint-led-blink.py
      );
    in
    stdenvNoCC.mkDerivation {
      pname = "framework-fingerprint-led-blink";
      inherit version;

      dontUnpack = true;

      nativeBuildInputs = [ makeWrapper ];

      installPhase = ''
        runHook preInstall

        install -Dm755 ${script}/bin/framework-fingerprint-led-blink \
          $out/bin/framework-fingerprint-led-blink
        wrapProgram $out/bin/framework-fingerprint-led-blink \
          --prefix PATH : ${lib.makeBinPath [ dbus ]}

        runHook postInstall
      '';

      meta = {
        description = "Blink the Framework power-button LED while fprintd waits for a fingerprint";
        platforms = lib.platforms.linux;
        mainProgram = "framework-fingerprint-led-blink";
      };
    };
}
