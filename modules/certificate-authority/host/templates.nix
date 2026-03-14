{
  flake.modules.nixos.step-host = {
    services.openssh.extraConfig = ''
      Include /etc/ssh/sshd_config.d/*
    '';
  };

  flake.modules.nixos.step-ca = {
    services.step-ca.settings = {
      templates.ssh.host = [
        {
          name = "sshd_config.tpl";
          type = "snippet";
          template = ./templates/sshd_config.tpl;
          path = "/etc/ssh/sshd_config.d/step-ca.conf";
          comment = "#";
          requires = [
            "Certificate"
            "Key"
          ];
        }
        {
          name = "ca.tpl";
          type = "snippet";
          template = ./templates/ca.tpl;
          path = "/etc/ssh/step-ca.pub";
          comment = "#";
        }
      ];
    };
  };
}
