{ config, ... }@flake:
{
  configurations.home = {
    # just my global config plus dev for linux
    chnorton = {
      system = "x86_64-linux";
      module = {lib, pkgs,config,...}:{
        imports = [ flake.config.unify.modules.dev.home ];
        systemd.user.services.opencode = {
          # TODO: secure further - this is basic-auth over http... bad
          Service = {
            # listen on all interfaces for opencode, password is set by OPENCODE_SERVER_PASSWORD
            ExecStart = lib.mkForce "${lib.getExe config.programs.opencode.package} serve --port 40123 --hostname 0.0.0.0";
            # FIXME: sops?
            EnvironmentFile = "/home/chnorton/.config/opencode/env";
          };
        };
      };
    };
  };
}
