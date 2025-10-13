{
  flake.modules.darwin.base = {
    system.primaryUser = "caleb";
    nix.settings.sandbox = true;
  };
}
