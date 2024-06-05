{
  inputs,
  pkgs,
  ...
}: let
  # unstable plugins for neovim nightly
  inherit (pkgs.unstable) vimPlugins;

  treesitterWithGrammars = vimPlugins.nvim-treesitter.withPlugins (plugins:
    with plugins; [
      lua
      luadoc
      nix
    ]);

  treesitter-parsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = treesitterWithGrammars.dependencies;
  };
in {
  home.packages = with pkgs; [
    unzip
    ripgrep
    fd
    alejandra
    nodejs # for copilot
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

    plugins = with vimPlugins; [
      treesitterWithGrammars
      telescope-fzf-native-nvim
      luasnip
    ];
  };

  home.sessionVariables.EDITOR = "nvim";

  home.file."./.config/nvim/" = {
    source = ./config;
    recursive = true;
  };

  home.file."./.config/nvim/lua/caleb/init.lua".text = ''
    vim.opt.runtimepath:append("${treesitter-parsers}")
  '';

  # Treesitter is configured as a locally developed module in lazy.nvim
  # we hardcode a symlink here so that we can refer to it in our lazy config
  home.file."./.local/share/nvim/nix/nvim-treesitter/" = {
    recursive = true;
    source = treesitterWithGrammars;
  };

  home.file."./.local/share/nvim/nix/telescope-fzf-native.nvim/" = {
    recursive = true;
    source = vimPlugins.telescope-fzf-native-nvim;
  };
  
  home.file."./.local/share/nvim/nix/luasnip/" = {
    recursive = true;
    source = vimPlugins.luasnip;
  };
}
