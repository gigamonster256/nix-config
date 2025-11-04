flake: {
  unify.modules.step-host.nixos =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {

      services.openssh.enable = lib.mkDefault true;

      environment.systemPackages = [
        pkgs.step-cli
      ];

      systemd.services.step-ca-bootstrap-host =
        let
          firewall-tool = lib.getExe pkgs.nixos-firewall-tool;
        in
        {
          description = "Bootstrap step-ca SSH host certificate";
          wantedBy = [ "sshd.service" ];
          before = [ "sshd.service" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };

          path = [ pkgs.iptables ];

          # open/close port 80 for ACME validation
          preStart = ''
            ${firewall-tool} open tcp 80
          '';

          postStart = ''
            ${firewall-tool} reset
          '';

          script =
            let
              inherit (config.networking) hostName;
              stepCli = lib.getExe pkgs.step-cli;
              caUrl = "https://certs.nortonweb.org";
              caFingerprint = flake.config.certificate-authority.rootCertFingerprint;
              fqdn = "${hostName}.penguin";
              sshDir = "/etc/ssh";
              stepKeyPath = "${sshDir}/ssh_host_step_key";
              stepCertPath = "${sshDir}/ssh_host_step_key-cert.pub";
              script = pkgs.writeShellApplication {
                name = "step-ca-bootstrap-host";
                text = ''
                  # Bootstrap step-ca if not already done
                  if [ ! -f "$(${stepCli} path)/config/defaults.json" ]; then
                    echo "Bootstrapping step-ca..."
                    ${stepCli} ca bootstrap \
                      --ca-url="${caUrl}" \
                      --fingerprint="${caFingerprint}"
                  fi

                  # Check if we already have a valid SSH host certificate
                  if [ -f "${stepCertPath}" ]; then
                  #   # Check if certificate is still valid (not expiring in next 24 hours)
                  #   if ${stepCli} ssh check-host --quiet "${fqdn}" 2>/dev/null; then
                  #     echo "Valid SSH host certificate already exists, skipping bootstrap"
                  #     exit 0
                  #   fi
                    exit 0
                  fi

                  # Create temporary directory for X.509 certificates
                  TMPDIR=$(mktemp -d)
                  trap 'rm -rf $TMPDIR' EXIT

                  echo "Requesting X.509 certificate for ${fqdn}..."
                  ${stepCli} ca certificate "${fqdn}" \
                    "$TMPDIR/host.crt" \
                    "$TMPDIR/host.key" \
                    --provisioner "acme"

                  echo "Requesting SSH host certificate using X.509 cert..."
                  ${stepCli} ssh certificate \
                    --insecure \
                    --no-password \
                    --host \
                    --x5c-cert "$TMPDIR/host.crt" \
                    --x5c-key "$TMPDIR/host.key" \
                    "${fqdn}" \
                    "${stepKeyPath}"

                  # Ensure proper permissions
                  chmod 600 "${stepKeyPath}"
                  chmod 644 "${stepCertPath}"

                  echo "Configuring sshd to use step-ca certificates..."
                  ${stepCli} ssh config \
                    --host \
                    --set Key=ssh_host_step_key \
                    --set Certificate=ssh_host_step_key-cert.pub

                  echo "SSH host certificate bootstrap complete"
                '';
              };
            in
            lib.getExe script;
        };
    };
}
