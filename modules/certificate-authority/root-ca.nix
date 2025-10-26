{
  # import my CA root certificate to all NixOS hosts
  unify.nixos = {
    security.pki.certificateFiles = [
      ./certs/root_ca.crt
    ];
  };
}
