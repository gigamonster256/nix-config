{
  packages.logitune =
    {
      lib,
      stdenv,
      fetchFromGitHub,
      cmake,
      ninja,
      pkg-config,
      qt6,
    }:
    stdenv.mkDerivation (finalAttrs: {
      pname = "logitune";
      version = "0.3.4";

      src = fetchFromGitHub {
        owner = "mmaher88";
        repo = "logitune";
        tag = "v${finalAttrs.version}";
        hash = "sha256-eCRuSBC+f9IWGfraqkPQgwG0xxBbQIC2RadLlbEJIpQ=";
      };

      # hardcoded absolute location for autostart
      postPatch = ''
        substituteInPlace CMakeLists.txt \
          --replace-fail /etc/xdg/autostart etc/xdg/autostart
      '';

      nativeBuildInputs = [
        cmake
        ninja
        pkg-config
        qt6.wrapQtAppsHook
      ];

      buildInputs = [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtsvg
        qt6.qtwayland
      ];

      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DBUILD_TESTING=OFF"
        "-DLOGITUNE_VERSION=${finalAttrs.version}"
      ];

      meta = {
        description = "Configure Logitech devices on Linux (Options+ clone)";
        homepage = "https://github.com/mmaher88/logitune";
        license = lib.licenses.gpl3Only;
        maintainers = with lib.maintainers; [ ];
        mainProgram = "logitune";
        platforms = lib.platforms.all;
      };
    });
}
