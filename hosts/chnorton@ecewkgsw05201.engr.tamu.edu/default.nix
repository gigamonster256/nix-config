{ self, ... }:
{
  # build this home-manager configuration in CI
  flake.ci.x86_64-linux.home = [ "chnorton@ecewkgsw05201.engr.tamu.edu" ];

  configurations.home = {
    "chnorton@ecewkgsw05201.engr.tamu.edu" = {
      system = "x86_64-linux";
      module =
        { lib, config, ... }:
        {
          imports = [
            self.modules.homeManager.dev
            self.modules.homeManager.opencode
          ];
          # overrride the opencode-web from home-manager settings
          programs.opencode.web = {
            # TODO: secure further - this is basic-auth over http... bad
            environmentFile = "/home/chnorton/.config/opencode/env";
            extraArgs = [
              "--hostname=0.0.0.0" # listen on all interfaces for opencode, password is set by OPENCODE_SERVER_PASSWORD
              "--cors=http://opencode.localhost" # allow remote connections from my machine
            ];
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

          programs.nh.autoUpgrade = {
            enable = true;
            flags = [
              "--refresh"
              "--no-nom"
              "--no-build-output"
            ];
          };
        };
    };
  };
}
