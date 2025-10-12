{
  imports = [
    ./sketchybar
    ./yabai

    ./aerospace.nix
  ];

  system.primaryUser = "caleb";

  nix.settings.sandbox = true;
}
