{ config, ... }@flake:
{
  unify.modules.step-user.home =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      home.packages = [
        pkgs.step-cli
      ];

      systemd.user.services.step-ca-bootstrap-user = {
        Unit = {
          Description = "Bootstrap step-ca client for user SSH";
          After = [ "network-online.target" ];
        };

        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        Install = {
          WantedBy = [ "default.target" ];
        };

        Service.ExecStart =
          let
            stepCli = lib.getExe pkgs.step-cli;
            caUrl = "https://certs.nortonweb.org";
            caFingerprint = flake.config.certificate-authority.rootCertFingerprint;
            script = pkgs.writeShellApplication {
              name = "step-ca-bootstrap-user";
              text = ''
                # Bootstrap step-ca if not already done
                if [ ! -f "$(${stepCli} path)/config/defaults.json" ]; then
                  echo "Bootstrapping step-ca for user..."
                  ${stepCli} ca bootstrap \
                    --ca-url="${caUrl}" \
                    --fingerprint="${caFingerprint}"
                  
                  # echo "Configuring SSH to trust CA signed hosts..."
                  # ${stepCli} ssh config
                  
                  echo "step-ca user bootstrap complete"
                else
                  echo "step-ca already bootstrapped for user"
                fi
              '';
            };
          in
          lib.getExe script;
      };
    };
}
