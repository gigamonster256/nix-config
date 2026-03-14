{
  nixpkgs.allowedUnfreePackages = [
    "steam"
    "steam-unwrapped"
  ];

  flake.modules.nixos.gaming = {
    programs.steam.enable = true;
    hardware.steam-hardware.enable = true;
    services.joycond.enable = true;
  };

  persistence.programs.nixos-home = {
    steam = {
      directories = [
        ".local/share/Steam"
        ".local/share/applications" # save installed game entries - a little crufty
      ];
    };
  };
}
