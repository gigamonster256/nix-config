{
  unify.nixos = {
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "admin@nortonweb.org";
        server = "https://certs.nortonweb.org/acme/acme/directory";
        webroot = "/var/lib/acme/acme-challenge";
        renewInterval = "*-*-* 00/12:00:00";
      };
    };
  };
}
