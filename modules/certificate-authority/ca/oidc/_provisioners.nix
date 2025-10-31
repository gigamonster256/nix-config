# TODO: see comments in ssh/_provisioners.nix about why this is done this way
{
  unify.modules.step-ca.nixos = {
    services.step-ca.settings = {
      authority.provisioners = [
        {
          type = "OIDC";
          name = "CalebWeb";
          clientID = "WqEZVYwT6QxmcGJxeInHzPMCsNUEoEvHSMZf3X9C";
          clientSecret = "";
          configurationEndpoint = "https://auth.calebweb.me/application/o/norton-web-ssh/.well-known/openid-configuration";
          admins = [ "n0603919@outlook.com" ];
          # domains = [ "smallstep.com" ];
          scopes = [
            "openid"
            "email"
          ];
          # listenAddress = ":10000";
          claims = {
            enableSSHCA = true;
            # maxTLSCertDuration = "8h";
            # defaultTLSCertDuration = "2h";
            # disableRenewal = true;
          };
          options = {
            x509 = {
              templateFile = ./deny-all.tpl;
            };
            ssh = {
              # templateFile = "templates/certs/ssh/default.tpl";
            };
          };
        }
      ];
    };
  };
}
