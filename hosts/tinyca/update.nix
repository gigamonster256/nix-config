# the tinyca raspi is too slow/low mem to re-evaluate itself so here's a module so another host can build it and copy the result over
{ self, config, ... }:
{
  flake.modules.nixos.tinyca-updater =
    { lib, pkgs, ... }:
    {
      # add binfmt support for qemu-user emulation of aarch64-linux on non-aarch64-linux hosts, so we can build the tinyca image on another host
      # not sure if this is needed since tinyca nixos config should be cached in gh actions
      boot.binfmt.emulatedSystems =
        lib.mkIf
          (!(pkgs.stdenv.hostPlatform.canExecute self.nixosConfigurations.tinyca.pkgs.stdenv.hostPlatform))
          [
            self.nixosConfigurations.tinyca.pkgs.stdenv.hostPlatform.system
          ];

      systemd.services.tinyca-update = {
        description = "Update tinyca";
        requires = [ "network.target" ];
        path = [
          pkgs.nixos-rebuild
          pkgs.openssh
        ];
        # use ssh host keys
        environment.NIX_SSHOPTS = "-i /etc/ssh/ssh_host_ed25519_key";
        script = "nixos-rebuild --flake ${config.meta.flake}#tinyca --refresh --accept-flake-config --target-host root@certs.nortonweb.org switch";
        serviceConfig = {
          Type = "oneshot";
        };
      };

      systemd.timers.tinyca-update = {
        description = "Update tinyca every day";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 8:26:00";
          Persistent = true;
        };
      };
    };
}
