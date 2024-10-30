{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  # unstable plugins for neovim unstable
  inherit (pkgs.unstable) vimPlugins;

  treesitterWithGrammars = vimPlugins.nvim-treesitter.withPlugins (plugins:
    with plugins; [
      # add additional plugins as needed
      # neovim comes with some grammars by default
      # see https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/ne/neovim-unwrapped/treesitter-parsers.nix
      # for details (or the equivalent file in neovim nightly/your nixpkgs checkout)
      nix
      elixir
      python
      cpp
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

  # packages neovim wants to see on the PATH
  runtimeDeps = with pkgs; [
    ripgrep
    fd
    nodejs # for copilot
  ];
in {
  programs.neovim = {
    enable = true;

    package = pkgs.unstable.neovim-unwrapped;

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

    extraWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      "${lib.makeBinPath runtimeDeps}"
    ];
  };

  home.sessionVariables.EDITOR = "nvim";

  home.file."./.config/nvim/lua/nix/init.lua".text =
    /*
    lua
    */
    ''
      vim.opt.rtp:append("${treesitter-parsers}")
    '';

  home.file = {
    # make config available at ~/.config/nvim
    "./.config/nvim/" = {
      source = inputs.neovim-config;
      recursive = true;
    };
    # make nix plugins available at ~/.local/share/nvim/nix
    "./.local/share/nvim/nix/" = {
      source = pluginsPath;
      recursive = true;
    };
  };

  # remove stale nvim lua cache
  # this could probably be narrowed down to the specific file (nix/init.lua) but this is fine for now
  home.activation = {
    clearNvimCache = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
      NVIM_CACHE="${config.xdg.cacheHome}/nvim/luac"
      if [[ -d "$NVIM_CACHE" ]]; then
        $DRY_RUN_CMD rm -rf "$VERBOSE_ARG" "$NVIM_CACHE"
      fi
    '';
  };
}
