{
  unify.modules.step-ca.nixos = {
    services.step-ca.settings = {
      templates.ssh.user = [
        {
          name = "config.tpl";
          type = "snippet";
          template = ./templates/config.tpl;
          path = "~/.ssh/config";
          comment = "#";
        }
        {
          name = "step_includes.tpl";
          type = "prepend-line";
          template = ./templates/step_includes.tpl;
          path = "\${STEPPATH}/ssh/includes";
          comment = "#";
        }
        {
          name = "step_config.tpl";
          type = "file";
          template = ./templates/step_config.tpl;
          path = "ssh/config";
          comment = "#";
        }
        {
          name = "known_hosts.tpl";
          type = "file";
          template = ./templates/known_hosts.tpl;
          path = "ssh/known_hosts";
          comment = "#";
        }
      ];
    };
  };
}
