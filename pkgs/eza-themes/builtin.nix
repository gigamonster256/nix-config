{
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  name = "eza-themes";
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/share/eza
    cp -aR $src/themes $out/share/eza/themes
  '';
  src = fetchFromGitHub {
    owner = "eza-community";
    repo = "eza-themes";
    rev = "main";
    sha256 = "sha256-vu6QLz0RvPavpD2VED25D2PJlHgQ8Yis+DnL+BPlvHw=";
  };
}
