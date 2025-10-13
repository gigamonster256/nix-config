let
  ntop =
    {
      writeShellApplication,
      moreutils,
      ripgrep,
      procps,
      findutils,
      recursive-cpu-usage,
    }:
    writeShellApplication {
      name = "ntop";

      runtimeInputs = [
        moreutils
        ripgrep
        procps
        findutils
        recursive-cpu-usage
      ];

      text = ''
        nd=$(pgrep nix-daemon | head -n1) && sudo parallel sh -c '
          secs=$(ps -o etimes= -p "$0");
          time=$(printf " %02dd %02dh %02dm %02ds " $((secs/(3600*24))) $((secs/3600%24)) $((secs%3600/60)) $((secs%60)));
          time="''${time//00m/   }";
          time="''${time//00h/   }";
          time="''${time//00d/   }";
          pid=$(printf "%07d" $0);
          echo "PID $pid $time $(recursive-cpu-usage $0)" $(cat /proc/$0/environ | tr "\\0" "\\n" \
           | rg "^(name)=(.+)" - --replace "\$2" | tr "\\n" " ")' -- $(tr ' ' '\n' < "/proc/$nd/task/$nd/children" | xargs -L 1 sh -c 'cat /proc/$0/task/*/children') \
           | sort | sed -s "s/ 00/   /g" | sed -s "s/ 0/  /g" | sed -s "s/m   s/m  0s/g"
      '';

      excludeShellChecks = [
        "SC2046" # expand pids to be processed by parallel
        "SC2016" # expand $0 only inside the sh script
      ];
    };
in
{ moduleWithSystem, ... }:
{
  perSystem =
    { self', pkgs, ... }:
    {
      packages.ntop = pkgs.callPackage ntop {
        inherit (self'.packages) recursive-cpu-usage;
      };
    };

  flake.modules.nixos.base = moduleWithSystem (
    { self', ... }:
    {
      environment.systemPackages = [
        # self'.packages.ntop # dont install globally
      ];
    }
  );
}
