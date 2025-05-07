{lib, ...}: {
  security.sudo.extraConfig = lib.mkAfter ''
    Defaults lecture=never
  '';
}
