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
      text = ''
        usage() {
          echo "Usage: jj-fetch [--depth N]" >&2
          exit 1
        }

        depth=""
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --depth)
              depth="$2"
              shift 2
              ;;
            *)
              usage
              ;;
          esac
        done

        if [ -n "$depth" ]; then
          find . -maxdepth "$depth" -type d -name ".jj" -prune -print0
        else
          find . -type d -name ".jj" -prune -print0
        fi | xargs -0 -r -P "''${JJ_FETCH_PARALLELISM:-4}" -I {} jj -R {}/.. git fetch --all-remotes
      '';
    };
}
