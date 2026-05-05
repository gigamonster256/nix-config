{
  flake.modules = {
    nixos.logitune =
      { pkgs, ... }:
      {
        services.udev.packages = [ pkgs.logitune ];
      };
    homeManager.logitune = {
      programs.logitune.enable = true;
    };
  };

  persistence.wrappers.homeManager = [
    "logitune"
  ];

  persistence.programs.homeManager = {
    # ledger-live = {
    #   directories = [
    #     ".config/Ledger Live"
    #     ".config/Ledger Wallet"
    #   ];
    # };
  };
}
