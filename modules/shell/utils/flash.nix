{
  packages.flash =
    {
      writeShellApplication,
      file,
      zstd,
      coreutils,
    }:
    writeShellApplication {
      name = "flash";

      runtimeInputs = [
        file
        zstd
        coreutils
      ];

      text =
        # bash
        ''
          if [ "$#" -ne 2 ]; then
            echo "Usage: flash <image-file> <device>"
            exit 1
          fi

          if [ "$(file "$1" --mime-type -b)" = "application/zstd" ]; then
            echo "Flashing zst using zstdcat | dd"
            ( set -x; zstdcat "$1" | sudo dd of="$2" iflag=fullblock oflag=direct status=progress conv=fsync,noerror bs=64k )
          elif [ "$(file "$1" --mime-type -b)" = "application/x-xz" ]; then
            echo "Flashing xz using xzcat | dd"
            ( set -x; xzcat "$1" | sudo dd of="$2" iflag=fullblock oflag=direct status=progress conv=fsync,noerror bs=64k )
          else
            echo "Flashing arbitrary file $1 to $2"
            ( set -x; sudo dd if="$1" of="$2" status=progress conv=fsync,noerror bs=64k )
          fi
        '';
    };

  unify.nixos =
    { pkgs, ... }:
    {
      environment.defaultPackages = [
        pkgs.flash
      ];
    };
}
