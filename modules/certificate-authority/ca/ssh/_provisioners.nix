# services.step-ca.settings being attrsOf anything causes issues with setting nested atts in multiple files
# luckily this is the only place that happens, but ideally the module system should concat the provisioners list
# TODO: fix this up somehow - will I need to define the entire settings type properly in nixpkgs?
{ config, ... }:
{
  unify.modules.step-ca.nixos = {
    services.step-ca.settings = {
      authority.provisioners = [
        # Allow SSH cert renewal via proof-of-possession
        {
          type = "SSHPOP";
          name = "sshpop";
          claims = {
            enableSSHCA = true;
          };
        }
        # allow any X509 key signed by our own root key to get it's corresponding ssh host key
        {
          type = "X5C";
          name = "x5c-ssh-bootstrap";
          roots = config.certificate-authority.rootCertBase64;
          claims = {
            enableSSHCA = true;
            disableRenewal = true;
            allowRenewalAfterExpiry = false;
            disableSmallstepExtensions = false;
          };
          options = {
            x509 = {
              templateFile = ./deny-all.tpl;
            };
            ssh = {
              templateFile = ./ssh-host-x509.tpl;
            };
          };
        }
      ];
    };
  };
}
