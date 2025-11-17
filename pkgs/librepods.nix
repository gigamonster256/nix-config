let
  librepods =
    {
      fetchFromGitHub,
      stdenv,
      qt6,
      libpulseaudio,

      cmake,
      pkg-config,
    }:
    stdenv.mkDerivation (finalAttrs: {
      pname = "librepods";
      version = "55d1a69";
      src = fetchFromGitHub {
        owner = "kavishdevar";
        repo = "librepods";
        rev = finalAttrs.version;
        hash = "sha256-8kSrV9XgbfzPZ5kEL1J0ovzs+hT0GxacUDjT0eJdmKU=";
      };
      prePatch = ''
        cd linux
      '';
      buildInputs = [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtconnectivity
        qt6.qtmultimedia
        libpulseaudio
      ];
      nativeBuildInputs = [
        cmake
        pkg-config
        qt6.wrapQtAppsHook
      ];
    });
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.librepods = pkgs.callPackage librepods {
      };
    };
}
