{
  inputs,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    alejandra
    nil
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # neovim nightly overlay is broken until 24.05 stabilizes
      #inputs.neovim-nightly-overlay.overlays.default
    ];
  };

  programs.neovim = {
    enable = true;
    # remove once overlay is fixed
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

    viAlias = true;
    vimAlias = true;
  };
  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
