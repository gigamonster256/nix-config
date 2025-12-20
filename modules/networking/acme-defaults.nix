{
  unify.nixos =
    { config, lib, ... }:
    let
      # derive acme-renew-* names from defined ACME certs
      acmeRenewNames = map (n: "acme-renew-" + n) (builtins.attrNames config.security.acme.certs);
    in
    {
      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "admin@nortonweb.org";
          server = "https://certs.nortonweb.org/acme/acme/directory";
          webroot = "/var/lib/acme/acme-challenge";
          # step ca defaults to 24 hr certs, so we renew more frequently
          renewInterval = "*-*-* 00/12:00:00";
          # however, the default RandomizedDelaySec is 24 hours, which doesnt work,
          # do we need to make all acme timers have a smaller randomized delay
        };
      };

      # override RandomizedDelaySec for all acme-renew-* timers
      systemd.timers = lib.genAttrs acmeRenewNames (_: {
        timerConfig.RandomizedDelaySec = lib.mkForce "1h";
      });
    };
}
