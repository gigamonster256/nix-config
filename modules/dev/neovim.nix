{ moduleWithSystem, ... }:
{
  # bring in my neovim config as pkgs.neovim
  # broken until nvim-treesitter issues are resolved
  # https://github.com/NixOS/nixpkgs/pull/472119
  nixpkgs.overlays = [
    # inputs.neovim.overlays.default
  ];

  flake.modules = {
    nixos.dev = {
      programs.nano.enable = false;
    };

    homeManager.dev = moduleWithSystem (
      { inputs', ... }:
      # { pkgs, ... }:
      {
        # home.packages = [ pkgs.neovim ];
        home.packages = [ inputs'.neovim.packages.neovim ];
        home.sessionVariables.EDITOR = "nvim";
        home.shellAliases = {
          nvom = "nvim";
          nivm = "nvim";
        };
        persistence.directories = [ ".config/github-copilot" ];
      }
    );
  };
}
