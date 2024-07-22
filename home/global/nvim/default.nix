{
  inputs,
  pkgs,
  lib,
  config,
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
  # https://stackoverflow.com/questions/68523367/in-nixpkgs-how-do-i-override-files-of-a-package-without-recompilation/68523368#68523368
  originalNvim = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
  wrappedNeovim = originalNvim.overrideAttrs (old: {
    name = "neovim-with-apps";
    nativeBuildInputs = [pkgs.makeWrapper];
    buildCommand = ''
      set -euo pipefail
      ${
        # Copy original files, for each split-output (`out`, `dev` etc.).
        # E.g. `${package.dev}` to `$dev`, and so on. If none, just "out".
        # Symlink all files from the original package to here (`cp -rs`),
        # to save disk space.
        # We could alternatiively also copy (`cp -a --no-preserve=mode`).
        lib.concatStringsSep "\n"
        (
          map
          (
            outputName: ''
              echo "Copying output ${outputName}"
              set -x
              cp -rs --no-preserve=mode "${originalNvim.${outputName}}" "''$${outputName}"
              set +x
            ''
          )
          (["out"] ++ (lib.optional (! pkgs.stdenv.isDarwin) "debug")) # separateDebugInfo shenanigans (https://github.com/NixOS/nixpkgs/issues/203380)
          # (old.outputs or ["out"])
        )
      }
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
