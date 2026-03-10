{
  unify.modules.dev.home =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      home.packages = [
        pkgs.jj-fetch # recursive fetch for jujutsu repos
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
}
