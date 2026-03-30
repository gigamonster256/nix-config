{ self, ... }:
{
  # build this home-manager configuration in CI
  flake.ci.x86_64-linux.home = [ "chnorton" ];

  configurations.home = {
    # just my global config plus dev for linux
    chnorton = {
      system = "x86_64-linux";
      module =
        { lib, config, ... }:
        {
          imports = [
            self.modules.homeManager.dev
            self.modules.homeManager.opencode
          ];
          # overrride the opencode-web from home-manager settings
          programs.opencode.web.extraArgs = [
            "--hostname=0.0.0.0" # listen on all interfaces for opencode, password is set by OPENCODE_SERVER_PASSWORD
          ];
          systemd.user.services.opencode-web = {
            # TODO: secure further - this is basic-auth over http... bad
            Service = {
              # FIXME: sops?
              # upstream PR: https://github.com/nix-community/home-manager/pull/8939
              EnvironmentFile = "/home/chnorton/.config/opencode/env";
            };
          };
          # use school email
          programs.git.settings.user.email = "chnorton@tamu.edu";

          # keep system shell bash but switch into zsh if its available
          programs.bash = {
            enable = true;
            package = null; # only declarative config
            # if hm-managed zsh is available, exec into it
            profileExtra = lib.optionalString config.programs.zsh.enable ''
              # Check if zsh exists and we're not already running it
              if [ -x "$(command -v zsh)" ] && [ "$SHELL" != "$(command -v zsh)" ] && [[ $- == *i* ]]
              then
                export SHELL="$(command -v zsh)"
                exec zsh -l
              fi
            '';
          };

          programs.zsh = {
            # source imperative config if it exists
            initContent = lib.mkAfter ''
              if [ -f ~/.zshrc.extra ]; then
                source ~/.zshrc.extra
              fi
            '';
          };
        };
    };
  };
}
