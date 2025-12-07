{ inputs, ... }:
{
  # bring in my neovim config as pkgs.neovim
  nixpkgs.overlays = [
    inputs.neovim.overlays.default
  ];

  unify.modules.dev.home =
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
}
