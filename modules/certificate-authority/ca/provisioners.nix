{ config, ... }:
{
  unify.modules.step-ca.nixos = {
    services.step-ca.settings = {
      authority.provisioners = [
        {
          type = "ACME";
          name = "default-acme";
          claims = {
            # enableSSHCA = true; # acme has no ssh cert capabilities
            disableRenewal = false;
            allowRenewalAfterExpiry = false;
            disableSmallstepExtensions = false;
          };
          # options = {
          # 	x509= {};
          # 	ssh= {};
          # };
        }
      ]
      # see TODO in the file for why the module is imported this way
      ++ (import ./ssh/_provisioners.nix { inherit config; })
        .unify.modules.step-ca.nixos.services.step-ca.settings.authority.provisioners
      ++ (import ./oidc/_provisioners.nix)
        .unify.modules.step-ca.nixos.services.step-ca.settings.authority.provisioners;
    };
  };
}
