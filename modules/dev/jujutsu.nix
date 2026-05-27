{
  flake.modules.homeManager.dev =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      home.packages = [
        pkgs.jj-fetch # recursive fetch for jujutsu repos
        pkgs.cut-release
      ];
      programs.jujutsu.enable = lib.mkDefault true;
      programs.jujutsu.settings = {
        user = {
          name = lib.mkDefault config.programs.git.settings.user.name;
          email = lib.mkDefault config.programs.git.settings.user.email;
        };
        ui = {
          merge-editor = lib.mkDefault ":builtin";
          default-command = lib.mkDefault [ "log" ];
          pager = lib.mkDefault ":builtin";
          diff-editor = lib.mkDefault ":builtin";
          diff-formatter = [
            (lib.getExe pkgs.difftastic)
            "--color=always"
            "$left"
            "$right"
          ];
        };
        aliases = {
          fetch = [
            (lib.getExe pkgs.jj-fetch)
          ];
          fresh = [
            "new"
            "trunk()"
          ];
          tug = [
            "bookmark"
            "move"
            "--from"
            "closest_bookmark(@)"
            "--to"
            "closest_pushable(@)"
          ];
        };
        revset-aliases = {
          "closest_bookmark(to)" = "heads(::to & bookmarks())";
          "closest_pushable(to)" = "heads(::to & ~description(exact:\"\") & (~empty() | merges()))";
          "desc(x)" = "description(x)";
        };
        signing = {
          behavior = "keep";
          backend = "gpg";
        };
        fix.tools.nixfmt = {
          # do not use globally but can be enabled per-repo with
          # `jj config set --repo fix.tools.nixfmt.enabled true`
          enabled = false;
          command = [ (lib.getExe pkgs.nixfmt) ];
          patterns = [ "glob:**/*.nix" ];
        };
        templates = {
          git_push_bookmark = "'gigamonster256/push-' ++ change_id.short()";
        };
      };
    };

  persistence.programs.homeManager = {
    jujutsu = {
      directories = [
        ".config/jj/repos"
      ];
    };
  };

  packages.cut-release =
    {
      writeShellApplication,
      jujutsu,
    }:
    writeShellApplication {
      name = "cut-release";
      runtimeInputs = [ jujutsu ];
      text = ''
        # make sure 1 arg was passed
        if [ "$#" -ne 1 ]; then
          echo "Usage: cut-release <tag>";
          exit 1;
        fi

        # add v prefix if not present
        if [[ "$1" != v* ]]; then
          tag="v$1";
        else
          tag="$1";
        fi

        jj desc -m "release: $tag"
        jj tag set "$tag"
      '';
    };
}
