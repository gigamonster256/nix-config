{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      security.sudo.extraConfig = lib.mkAfter ''
        Defaults lecture=never
      '';
    };
}
