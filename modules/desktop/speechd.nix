{
  # nixpkgs.overlays = [
  #   (_final: prev: {
  #     firefox = prev.firefox.override {
  #       cfg = {
  #         speechSynthesisSupport = false;
  #       };
  #     };
  #     kdePackages = prev.kdePackages.overrideScope (
  #       _kfinal: kprev: {
  #         okular = kprev.okular.overrideAttrs (oldAttrs: {
  #           # remove qtspeech from buildInputs and tell CMake to not require it
  #           buildInputs = lib.filter (dep: dep.pname != "qtspeech") oldAttrs.buildInputs;
  #           cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
  #             "-DFORCE_NOT_REQUIRED_DEPENDENCIES=Qt6TextToSpeech"
  #           ];
  #         });
  #         ktextwidgets = kprev.ktextwidgets.overrideAttrs (oldAttrs: {
  #           # remove qtspeech from buildInputs and disable text to speech
  #           buildInputs = lib.filter (dep: dep.pname != "qtspeech") oldAttrs.buildInputs;
  #           cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
  #             "-DWITH_TEXT_TO_SPEECH=OFF"
  #           ];
  #         });
  #       }
  #     );
  #   })
  # ];

  unify.nixos =
    { lib, ... }:
    {
      # see <nixpkgs>/nixos/modules/services/misc/graphical-desktop.nix
      services.speechd.enable = lib.mkOverride 750 false;
    };
}
