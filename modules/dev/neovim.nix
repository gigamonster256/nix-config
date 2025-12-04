{
  unify.modules.dev.home =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.neovim ];
      persistence.directories = [ ".config/github-copilot" ];
    };
}
