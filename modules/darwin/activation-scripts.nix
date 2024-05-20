{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  inherit (pkgs) stdenv;

  cfg = config.system;
in {
  config = {
    system.activationScripts.script.text = mkForce ''
      #! ${stdenv.shell}
      set -e
      set -o pipefail
      export PATH="${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin:@out@/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin"

      systemConfig=@out@

      _status=0
      trap "_status=1" ERR

      # Ensure a consistent umask.
      umask 0022

      ${cfg.activationScripts.preActivation.text}

      # We run `etcChecks` again just in case someone runs `activate`
      # directly without `activate-user`.
      ${cfg.activationScripts.etcChecks.text}
      ${cfg.activationScripts.extraActivation.text}
      ${cfg.activationScripts.groups.text}
      ${cfg.activationScripts.users.text}
      ${cfg.activationScripts.applications.text}
      ${cfg.activationScripts.pam.text}
      ${cfg.activationScripts.patches.text}
      ${cfg.activationScripts.etc.text}
      ${cfg.activationScripts.defaults.text}
      ${cfg.activationScripts.launchd.text}
      ${cfg.activationScripts.nix-daemon.text}
      ${cfg.activationScripts.time.text}
      ${cfg.activationScripts.networking.text}
      ${cfg.activationScripts.wireless.text}
      ${cfg.activationScripts.keyboard.text}
      ${cfg.activationScripts.fonts.text}
      ${cfg.activationScripts.nvram.text}

      ${cfg.activationScripts.postActivation.text}

      # Make this configuration the current configuration.
      # The readlink is there to ensure that when $systemConfig = /system
      # (which is a symlink to the store), /run/current-system is still
      # used as a garbage collection root.
      ln -sfn "$(readlink -f "$systemConfig")" /run/current-system

      # Prevent the current configuration from being garbage-collected.
      ln -sfn /run/current-system /nix/var/nix/gcroots/current-system

      exit $_status
    '';
  };
}
