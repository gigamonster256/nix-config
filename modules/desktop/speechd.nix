{
  nixpkgs.overlays = [
    (_final: prev: {
      firefox = prev.firefox.override {
        cfg = {
          speechSynthesisSupport = false;
        };
      };
    })
  ];

  unify.nixos =
    { lib, ... }:
    {
      # see <nixpkgs>/nixos/modules/services/misc/graphical-desktop.nix
      services.speechd.enable = lib.mkOverride 750 false;
    };
}
