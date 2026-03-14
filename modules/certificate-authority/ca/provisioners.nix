{ config, ... }:
{
  flake.modules.nixos.step-ca = {
    services.step-ca.settings = {
      authority.provisioners = [
        {
          type = "ACME";
          name = "acme";
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
        .flake.modules.nixos.step-ca.services.step-ca.settings.authority.provisioners
      ++ (import ./oidc/_provisioners.nix)
        .flake.modules.nixos.step-ca.services.step-ca.settings.authority.provisioners;
    };
  };
}
