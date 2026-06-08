{ inputs, ... }:
{
  # bring in my neovim config as pkgs.neovim
  nixpkgs.overlays = [
    inputs.neovim.overlays.default
  ];

  flake.modules = {
    nixos.dev = {
      programs.nano.enable = false;
    };

    homeManager.dev = 
      { pkgs, ... }:
      {
        home.packages = [ pkgs.neovim ];
        home.sessionVariables.EDITOR = "nvim";
        home.shellAliases = {
          nvom = "nvim";
          nivm = "nvim";
        };
        persistence.directories = [ ".config/github-copilot" ];
      };
  };
}
