{
  unify.modules.step-host.nixos = {
    services.openssh.extraConfig = ''
      Include /etc/ssh/sshd_config.d/*
    '';
  };

  unify.modules.step-ca.nixos = {
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
