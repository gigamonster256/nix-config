{ self, inputs, ... }:
{
  # build this home-manager configuration in CI
  flake.ci.x86_64-linux.home = [ "chnorton@ecewkgsw05201.engr.tamu.edu" ];

  configurations.home = {
    "chnorton@ecewkgsw05201.engr.tamu.edu" = {
      system = "x86_64-linux";
      module =
        {
          lib,
          config,
          pkgs,
          ...
        }:
        let
          # The TFTP serve directory lives on the per-user runtime tmpfs
          # ($XDG_RUNTIME_DIR, i.e. /run/user/<uid>) instead of in $HOME, so
          # student uploads never touch the home directory and are discarded on
          # logout/reboot.
          #
          # NOTE: an unprivileged user cannot mount a tmpfs, so we can't give
          # this directory its own `size=` cap. The cap below is therefore
          # enforced in software by the reset timer; the real hard bound is the
          # shared /run/user/<uid> tmpfs (normally 10% of RAM).
          tftpDirName = "ecen602-tftp";

          # Total size limit for the served directory, in MiB. Must stay well
          # above the ~34 MiB seed file so a legitimate reset never loops.
          capMiB = 256;

          # Wipe + reseed unconditionally at least this often (seconds).
          fullResetSeconds = 3600;

          # How often the guard timer checks the size cap / reset deadline.
          checkSeconds = 60;

          # Read-only seed restored on every reset. Covers the ECEN 602 MP3
          # rubric edge cases (block boundaries, netascii CRs, 34 MiB file for
          # block wrap-around / concurrency / timeout tests).
          seed =
            pkgs.runCommand "ecen602-tftp-seed"
              {
                nativeBuildInputs = [ pkgs.python3 ];
              }
              ''
                mkdir -p $out
                python3 - <<'PY'
                import os

                out = os.environ["out"]


                def blob(n):
                    return bytes(((i * 131) + 7) % 256 for i in range(n))


                def write(name, data):
                    with open(os.path.join(out, name), "wb") as f:
                        f.write(data)


                # Empty + exact block-boundary files.
                write("empty.bin", b"")
                write("binary-512.bin", blob(512))
                write("binary-513.bin", blob(513))

                # Rubric cases (1) and (2).
                write("binary-2047.bin", blob(2047))
                write("binary-2048.bin", blob(2048))

                # Netascii edge cases: "netascii-crs.txt" contains exactly two CR
                # bytes, "text-lf.txt" exercises local-newline <-> CRLF conversion.
                write("netascii-crs.txt", b"first line\r\nsecond line\r\n")
                write("text-lf.txt", b"alpha\nbeta\ngamma\n")

                # Rubric cases (4), (6) and (7): a 34 MiB file for block number
                # wrap-around, concurrent transfers and client-timeout testing.
                # 544 * 65536 == 34 MiB exactly.
                with open(os.path.join(out, "binary-34mib.bin"), "wb") as f:
                    block = blob(65536)
                    for _ in range(544):
                        f.write(block)
                PY

                cat > $out/README.txt <<'EOF'
                ECEN 602 TFTP seed files (restored on a timer; treat as read-only).

                  empty.bin           0 bytes
                  binary-512.bin      exactly one full 512-byte block
                  binary-513.bin      one full block plus one byte
                  binary-2047.bin     rubric case (2)
                  binary-2048.bin     rubric case (1)
                  netascii-crs.txt    netascii containing two CRs (rubric case (3))
                  text-lf.txt         LF line endings (netascii conversion)
                  binary-34mib.bin    34 MiB, block-number wrap-around (case (4))

                Downloads use "get"; "put" fails with FILE_ALREADY_EXISTS for any
                name listed above.
                EOF
              '';

          # Wipes the serve directory and restores the seed whenever it exceeds
          # the size cap or the full-reset deadline has elapsed.
          reset = pkgs.writeShellApplication {
            name = "ecen602-tftp-reset";
            runtimeInputs = with pkgs; [
              coreutils
              findutils
            ];
            text = ''
              dir="''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/${tftpDirName}"
              seed="${seed}"
              stamp="''${XDG_RUNTIME_DIR}/${tftpDirName}.last-reset"
              cap_kb=${toString (capMiB * 1024)}
              interval_s=${toString fullResetSeconds}

              mkdir -p "$dir"

              now="$(date +%s)"
              last=0
              if [[ -r "$stamp" ]]; then
                last="$(<"$stamp")"
              fi

              size_kb="$(du -sk "$dir" | cut -f1)"

              reset=0
              # The serve dir is recreated empty whenever the service (re)starts
              # (RuntimeDirectory), but the reset stamp lives outside it and
              # survives, so always reseed an empty dir.
              if [ -z "$(ls -A "$dir")" ]; then
                reset=1
              fi
              if (( now - last >= interval_s )); then
                reset=1
              fi
              if (( size_kb > cap_kb )); then
                reset=1
              fi

              if (( reset )); then
                # "$dir" may have been left read-only (see the `cp -a` note
                # below); make sure we can clear it before repopulating.
                chmod u+rwx "$dir"
                find "$dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
                cp -a "$seed"/. "$dir"/
                # `cp -a` also copies the seed dir's own (read-only) mode onto
                # "$dir"; restore write access so the server can accept uploads.
                chmod u+rwx "$dir"
                printf '%s' "$now" > "$stamp"
                echo "ecen602-tftp: reset (used ''${size_kb}KiB of ''${cap_kb}KiB cap)"
              fi
            '';
          };
        in
        {
          imports = [
            self.modules.homeManager.dev
            self.modules.homeManager.opencode

            inputs.computer-networking.homeManagerModules.default
          ];

          # ECEN 602 machine problem servers (all except http_server)
          services.ecen602 = {
            echos.enable = true;
            sbcp.enable = true;
            tftp.enable = true;
            http-proxy.enable = true;

            # Serve from the per-user runtime tmpfs (see notes above).
            tftp.serveRoot = "%t/${tftpDirName}";
          };

          # Seed the serve directory before serving; systemd owns/creates the
          # tmpfs directory and removes it when the service stops.
          systemd.user.services.ecen602-tftp.Service = {
            RuntimeDirectory = tftpDirName;
            StateDirectory = lib.mkForce [ ];
            ExecStartPre = "${reset}/bin/ecen602-tftp-reset";
          };

          systemd.user.services.ecen602-tftp-reset = {
            Unit.Description = "Reset the ECEN 602 TFTP serve directory";
            Service = {
              Type = "oneshot";
              ExecStart = "${reset}/bin/ecen602-tftp-reset";
            };
          };

          systemd.user.timers.ecen602-tftp-reset = {
            Unit.Description = "Periodically reset/cap the ECEN 602 TFTP serve directory";
            Timer = {
              OnBootSec = "30s";
              OnUnitActiveSec = "${toString checkSeconds}s";
            };
            Install.WantedBy = [ "timers.target" ];
          };

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
