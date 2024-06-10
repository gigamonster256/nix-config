{
  inputs,
  pkgs,
  ...
}: let
  # unstable plugins for neovim nightly
  inherit (pkgs.unstable) vimPlugins;

  treesitterWithGrammars = vimPlugins.nvim-treesitter.withPlugins (plugins:
    with plugins; [
      # add additional plugins as needed
      # neovim comes with some grammars by default
      # see https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/ne/neovim-unwrapped/treesitter-parsers.nix
      # for details (or the equivalent file in neovim nightly/your nixpkgs checkout)
      nix
    ]);

  treesitter-parsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = treesitterWithGrammars.dependencies;
  };

  doNotLoad = plugin: {
    inherit plugin;
    optional = true;
  };

  pluginToLink = plugin: {
    name = plugin.pname;
    path = plugin;
  };

  neovimPlugins = with vimPlugins; [
    treesitterWithGrammars
    telescope-fzf-native-nvim
    luasnip
    lazy-nvim
  ];

  pluginsPath = pkgs.linkFarm "nvim-plugins" (map pluginToLink neovimPlugins);
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

    # do not auto load plugins (taken care of by lazy.nvim)
    # simple plugins can be added by lazy and by default
    # are downloaded and installed to ~/.local/share/nvim/lazy
    # however more complex plugins like treesitter require
    # more setup from nixpkgs and can be added to the neovimPlugins list.
    # (things that require a build step or have dependencies that need to be built)
    # To tell lazy to load nix based plugins, add {dev = true,}
    # to the plugin settings in the lazy config
    plugins = map doNotLoad neovimPlugins;
  };

  home.sessionVariables.EDITOR = "nvim";

  home.file."./.config/nvim/" = {
    source = ./config;
    recursive = true;
  };

  home.file."./.config/nvim/lua/caleb/init.lua".text = ''
    vim.opt.rtp:append("${treesitter-parsers}")
  '';

  # make nix plugins available at ~/.local/share/nvim/nix
  home.file."./.local/share/nvim/nix/" = {
    source = pluginsPath;
    recursive = true;
  };
}
