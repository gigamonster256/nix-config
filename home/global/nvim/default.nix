{
  inputs,
  pkgs,
  lib,
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

  # packages neovim wants to see on the PATH
  runtimeDeps = with pkgs; [
    ripgrep
    fd
    nodejs # for copilot
  ];

  # wrap runtime dependencies in a PATH prefix (only accessible to neovim)
  wrappedNeovim = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default.overrideAttrs (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [pkgs.makeBinaryWrapper];
    postFixup = ''
      wrapProgram $out/bin/nvim \
        --prefix PATH : ${lib.makeBinPath runtimeDeps}
    '';
  });
in {
  programs.neovim = {
    enable = true;

    package = wrappedNeovim;

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

  home.file."./.config/nvim/lua/nix/init.lua".text = ''
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
}
