{ inputs, ... }:
{
  unify.modules.no-vts.nixos =
    { lib, pkgs, ... }:
    {
      # disable gettys on VTs
      console.enable = lib.mkForce false;

      # disable VTs entirely in kernel
      boot.kernelPatches = [
        {
          name = "disable-vts";
          patch = null;
          structuredExtraConfig = {
            VT = lib.kernel.no;
          }
          # stuff that is now unused
          // lib.genAttrs [
            "FRAMEBUFFER_CONSOLE"
            "FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER"
            "FRAMEBUFFER_CONSOLE_DETECT_PRIMARY"
            "FRAMEBUFFER_CONSOLE_ROTATION"
            "RC_CORE"
          ] (_: lib.mkForce lib.kernel.unset);
        }
      ];

      # compatibility with serial logging
      boot.kernelParams = [
        "plymouth.graphical"
      ];

      # latest sddm
      services.displayManager.sddm.package = pkgs.kdePackages.sddm.override {
        sddm-unwrapped = pkgs.kdePackages.sddm.unwrapped.overrideAttrs {
          version = "develop";
          src = pkgs.fetchFromGitHub {
            owner = "sddm";
            repo = "sddm";
            rev = "dfa5315fd600760f8f3abddf7fb704202ffb07b3";
            hash = "sha256-kcrcgXpCMeMLRmXxcRbtwuvoLotmMZDMSCIDYI5v8F4=";
          };
          # override patching (updating upstream patches/removing applied ones)
          patches = [
            "${inputs.nixpkgs}/pkgs/applications/display-managers/sddm/greeter-path.patch"
            ./patches/sddm-ignore-config-mtime.patch
            "${inputs.nixpkgs}/pkgs/applications/display-managers/sddm/sddm-default-session.patch"
          ];
        };
      };
    };
}
