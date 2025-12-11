flake: {
  unify.nixos =
    { lib, config, ... }:
    lib.mkIf (flake.config.static-ips ? ${config.networking.hostName}) (
      let
        ip = flake.config.static-ips.${config.networking.hostName};
      in
      {
        networking.interfaces.${ip.interface} = {
          ipv4.addresses = [
            {
              inherit (ip) address;
              inherit (ip) prefixLength;
            }
          ];
        };
      }
    );

}
