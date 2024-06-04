# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # use native macOS arm version of trilium-desktop
    trilium-desktop = prev.trilium-desktop.overrideAttrs (oldAttrs: {
      meta.platforms = [
        "aarch64-darwin"
      ];
      version = "0.63.6";
      src = ../trilium-mac-arm64-0.63.6.zip;
    });
    # disable systemd on darwin for man-db
    man = prev.man.overrideAttrs (oldAttrs: {
      configureFlags = let
        systemdtmpfilesdir =
          if final.stdenv.hostPlatform.isDarwin
          then "no"
          else "${placeholder "out"}/lib/tmpfiles.d";
        systemdsystemunitdir =
          if final.stdenv.hostPlatform.isDarwin
          then "no"
          else "${placeholder "out"}/lib/systemd/system";
      in
        [
          "--disable-setuid"
          "--disable-cache-owner"
          "--localstatedir=/var"
          "--with-config-file=${placeholder "out"}/etc/man_db.conf"
          "--with-systemdtmpfilesdir=${systemdtmpfilesdir}"
          "--with-systemdsystemunitdir=${systemdsystemunitdir}"
          "--with-pager=less"
        ]
        ++ final.lib.optionals final.stdenv.hostPlatform.isDarwin [
          "ac_cv_func__set_invalid_parameter_handler=no"
          "ac_cv_func_posix_fadvise=no"
          "ac_cv_func_mempcpy=no"
        ];
    });

    # something funky is going on with gitstatus
    gitstatus = prev.gitstatus.overrideAttrs (oldAttrs: {
      installCheckPhase = ''
        echo "skipping tests"
      '';
    });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
