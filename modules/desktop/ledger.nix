{
  unify.modules.crypto = {
    nixos =
      { pkgs, ... }:
      {
        services.udev.packages = [ pkgs.ledger-udev-rules ];
      };
    home = {
      programs.ledger-live.enable = true;
    };
  };

  persistence.wrappers.homeManager = [
    {
      name = "ledger-live";
      packageName = "ledger-live-desktop";
    }
  ];

  persistence.programs.homeManager = {
    ledger-live = {
      directories = [
        ".config/Ledger Live"
        ".config/Ledger Wallet"
      ];
    };
  };
}
