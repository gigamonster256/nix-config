# flake module for certificate authority defaults
let
  module =
    { lib, config, ... }:
    let
      inherit (lib) types;
      cfg = config.certificate-authority;
    in
    {
      options.certificate-authority = {
        rootCertPath = lib.mkOption {
          type = types.path;
          description = "Path to the root CA certificate.";
        };

        # with there was a builtin base64 or even a clean way to do IFD at the flake module level
        # FIXME: make this better somhow
        rootCertBase64 = lib.mkOption {
          type = types.str;
          description = "Base64-encoded root CA certificate.";
        };

        rootCertFingerprint = lib.mkOption {
          type = types.str;
          description = "fingerprint of the root CA certificate.";
        };

        intermediateCertPath = lib.mkOption {
          type = types.path;
          description = "Path to the intermediate CA certificate.";
        };
      };

      config = {
      };
    };
in
{ config, ... }:
{
  # Provide the module to be imported by NixOS configurations
  imports = [ module ];

  # export the module for use in other flakes
  flake.modules.flake.certificate-authority = module;

  # set paths to certs
  certificate-authority = {
    rootCertPath = ./certs/root_ca.crt;
    intermediateCertPath = ./certs/intermediate_ca.crt;
    rootCertBase64 = builtins.readFile ./certs/root_ca.base64;
    rootCertFingerprint = builtins.readFile ./certs/root_ca.fingerprint;
  };

  # configure step-ca to use the certs from above
  unify.modules.step-ca.nixos =
    { lib, ... }:
    {
      services.step-ca.settings = {
        root = lib.mkDefault config.certificate-authority.rootCertPath;
        crt = lib.mkDefault config.certificate-authority.intermediateCertPath;
      };
    };

  # import my CA root certificate to all NixOS hosts
  unify.nixos = {
    security.pki.certificateFiles = [
      config.certificate-authority.rootCertPath
    ];
  };
}
