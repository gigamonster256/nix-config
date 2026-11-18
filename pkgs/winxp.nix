{
  packages.winxp =
    {
      lib,
      writeShellApplication,
      qemu,
      qemu-utils,
      coreutils,
      fetchurl,
    }:
    let
      # Windows XP is not freely redistributable. This only pins the copy that
      # is archived on the Internet Archive: English, Service Pack 3, original
      # volume-license media (so no activation is required) with the product
      # key published alongside it.
      iso = fetchurl {
        name = "windows-xp-pro-sp3-x86.iso";
        url = "https://archive.org/download/WinXPProSP3x86/en_windows_xp_professional_with_service_pack_3_x86_cd_vl_x14-73974.iso";
        hash = "sha256-/YyNQsFYHodnIX/oAL/A1WScCtINdUySfWx2PkRtGSc=";
      };

      productKey = "MRX3F-47B9T-2487J-KWKMF-RPWBY";
    in
    writeShellApplication {
      name = "winxp";
      runtimeInputs = [
        qemu
        qemu-utils
        coreutils
      ];

      meta = {
        description = "Boot a persistent Windows XP virtual machine with QEMU";
        mainProgram = "winxp";
        license = lib.licenses.mit;
        maintainers = [ lib.maintainers.gigamonster256 ];
      };

      text = ''
        usage() {
          cat <<'EOF'
        Boot a persistent Windows XP VM with QEMU.

        Usage: winxp [options] [-- extra qemu arguments...]

        Options:
          --iso PATH    Windows XP install CD image (default: the SP3 ISO
                        fetched from the Internet Archive by this package)
          --no-iso      boot without the install CD attached
          --disk PATH   qcow2 disk image (default: $WINXP_HOME/disk.qcow2)
          --ram MB      guest RAM in MiB (default: 512)
          --smp N       virtual CPUs (default: 1)
          --reset       delete the disk image and start over
          -h, --help    show this help

        Environment:
          WINXP_ISO       path to a Windows XP ISO (set to "" to boot without one)
          WINXP_HOME      data directory (default: ''${XDG_DATA_HOME:-~/.local/share}/winxp)
          WINXP_DISK_SIZE size of a freshly created disk image (default: 16G)
          WINXP_DISPLAY   QEMU display backend (default: gtk)
          WINXP_AUDIO     QEMU audio backend: auto, pa, pipewire, none (default: auto)

        Examples:
          winxp            install (on a fresh disk) or boot Windows XP
          winxp --no-iso   boot the installed system without the CD attached
          winxp --reset    throw the disk away and start over
        EOF
        }

        default_iso="${iso}"
        iso="''${WINXP_ISO-$default_iso}"
        home="''${WINXP_HOME:-''${XDG_DATA_HOME:-$HOME/.local/share}/winxp}"
        disk=""
        ram=512
        smp=1
        reset=""
        display="''${WINXP_DISPLAY:-gtk}"
        audio="''${WINXP_AUDIO:-auto}"
        disk_size="''${WINXP_DISK_SIZE:-16G}"
        extra=()

        while (( $# > 0 )); do
          case "$1" in
            --iso)
              iso="$2"
              shift 2
              ;;
            --no-iso)
              iso=""
              shift
              ;;
            --disk)
              disk="$2"
              shift 2
              ;;
            --ram)
              ram="$2"
              shift 2
              ;;
            --smp)
              smp="$2"
              shift 2
              ;;
            --reset)
              reset=1
              shift
              ;;
            -h | --help)
              usage
              exit 0
              ;;
            --)
              shift
              extra+=("$@")
              break
              ;;
            *)
              echo "winxp: unknown argument: $1" >&2
              usage >&2
              exit 1
              ;;
          esac
        done

        if [[ -n "$iso" ]]; then
          if [[ ! -f "$iso" ]]; then
            echo "winxp: ISO image not found: $iso" >&2
            exit 1
          fi
          iso="$(realpath "$iso")"
        fi

        if [[ -n "$disk" ]]; then
          home="$(dirname "$disk")"
        else
          disk="$home/disk.qcow2"
        fi

        mkdir -p "$home"

        if [[ -n "$reset" ]]; then
          rm -f "$disk"
        fi

        if [[ ! -e "$disk" ]]; then
          if [[ -z "$iso" ]]; then
            echo "winxp: no disk image at $disk and no Windows XP ISO given." >&2
            echo "winxp: boot without --no-iso (or with --iso PATH) to install." >&2
            exit 1
          fi
          qemu-img create -q -f qcow2 "$disk" "$disk_size"
          echo "winxp: created $disk ($disk_size)"
        fi

        if [[ -r /dev/kvm && -w /dev/kvm ]]; then
          machine=(-machine pc -accel kvm)
          cpu=(-cpu host)
        else
          machine=(-machine pc)
          cpu=(-cpu max)
          echo "winxp: no access to /dev/kvm, falling back to TCG emulation (slow)" >&2
        fi

        if [[ "$audio" == "auto" ]]; then
          if [[ -n "''${PULSE_SERVER:-}" || -S "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pulse/native" ]]; then
            audio="pa"
          else
            audio="none"
          fi
        fi

        audio_args=()
        case "$audio" in
          none | "") ;;
          *) audio_args=(-audio "$audio,model=ac97") ;;
        esac

        cd_args=()
        boot_args=(-boot order=c)
        if [[ -n "$iso" ]]; then
          cd_args=(-cdrom "$iso")
          # try the CD first, the XP installer only boots after a keypress so
          # the post-install reboot lands on the disk instead
          boot_args=(-boot "order=dc,menu=on")
        fi

        echo "winxp: disk  $disk"
        echo "winxp: cdrom ''${iso:-none}"
        echo "winxp: ram   ''${ram} MiB, smp ''${smp}, display ''${display}, audio ''${audio}"
        if [[ "$iso" == "$default_iso" ]]; then
          echo "winxp: SP3 volume-license ISO; setup wants product key ${productKey}"
        fi

        exec qemu-system-i386 \
          -name "Windows XP" \
          "''${machine[@]}" \
          "''${cpu[@]}" \
          -m "$ram" \
          -smp "$smp" \
          -rtc base=localtime,clock=host \
          -vga std \
          -usb \
          -device usb-tablet \
          -nic user,model=rtl8139 \
          "''${audio_args[@]}" \
          -drive "file=$disk,if=ide,media=disk,format=qcow2,cache=writeback" \
          "''${cd_args[@]}" \
          "''${boot_args[@]}" \
          -display "$display" \
          "''${extra[@]}"
      '';
    };
}
