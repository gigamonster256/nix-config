{
  unify.modules.dev.home =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.neovim ];
      impermanence.directories = [ ".config/github-copilot" ];
    };
}
