flake: {
  flake.modules.homeManager.dev =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      home.packages = [ (pkgs.gitignore-update.override { inherit (config.programs.git) ignores; }) ];
      programs.git = {
        enable = lib.mkDefault true;
        signing.format = lib.mkDefault "openpgp";
        ignores = [
          # nix dev things
          ".direnv/"
          "result"
          "result-*"
          ".envrc"
          ".devenv/"
          # .vscode settings
          ".vscode/"
          # secrets
          ".env"
        ];
        settings = {
          user = {
            name = lib.mkDefault flake.config.meta.owner.name;
            email = lib.mkDefault flake.config.meta.owner.email;
          };
          alias = {
            exec = lib.mkDefault "!exec ";
          };
          init.defaultBranch = "master";
          diff.external = lib.mkDefault (lib.getExe pkgs.difftastic);
        };
      };
    };

  packages.gitignore-update =
    {
      lib,
      writeShellApplication,
      gitMinimal,
      ignores ? [ ],
    }:
    writeShellApplication {
      name = "gitignore-update";
      runtimeInputs = [ gitMinimal ];
      text = ''
        git_root=$(git rev-parse --show-toplevel 2>/dev/null)
        if [ -z "$git_root" ]; then
          echo "Error: Not in a git repository" >&2
          exit 1
        fi

        gitignore="$git_root/.gitignore"
        touch "$gitignore"

        ${lib.concatMapStringsSep "\n" (ignore: ''
          if ! grep -qxF ${lib.escapeShellArg ignore} "$gitignore"; then
            echo ${lib.escapeShellArg ignore} >> "$gitignore"
          fi
        '') ignores}
      '';
    };
}
