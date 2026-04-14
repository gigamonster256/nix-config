{
  packages.jj-fetch =
    {
      writeShellApplication,
      findutils,
      jujutsu,
    }:
    writeShellApplication {
      name = "jj-fetch";
      runtimeInputs = [
        findutils
        jujutsu
      ];
      # recurse and find ".jj" directories, then for each one, run "jj git fetch --all-remotes" in the parent directory
      text = ''
        find . -type d -name ".jj" -prune -print0 | xargs -0 -r -P "''${JJ_FETCH_PARALLELISM:-4}" -I {} jj -R {}/.. git fetch --all-remotes
      '';
    };
}
