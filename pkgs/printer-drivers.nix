{
  nixpkgs.allowedUnfreePackages = [
    "cups-brother-hll2315dw"
  ];

  packages.cups-brother-hll2315dw =
    {
      lib,
      stdenv,
      fetchurl,
      cups,
      dpkg,
      gnused,
      makeWrapper,
      ghostscript,
      file,
      a2ps,
      coreutils,
      perl,
      gnugrep,
      which,
    }:

    let
      version = "3.2.1-1";
      lprdeb = fetchurl {
        url = "https://download.brother.com/welcome/dlf103310/hll2315dwlpr-${version}.i386.deb";
        hash = "sha256-RW2nQkyBzk6l6ee5SWWEeWMpIZKskAeviIkjbQSv61s=";
      };

      cupsdeb = fetchurl {
        url = "https://download.brother.com/welcome/dlf103314/hll2315dwcupswrapper-${version}.i386.deb";
        hash = "sha256-1Cb45LisVVj7mZEY8Al4vWyHy/UF0j22mbFX4i6vAus=";
      };

    in
    stdenv.mkDerivation {
      pname = "cups-brother-hll2315dw";
      inherit version;

      nativeBuildInputs = [ makeWrapper ];
      buildInputs = [
        cups
        ghostscript
        dpkg
        a2ps
      ];

      dontUnpack = true;

      installPhase = ''
        mkdir -p $out
        dpkg-deb -x ${cupsdeb} $out
        dpkg-deb -x ${lprdeb} $out

        substituteInPlace $out/opt/brother/Printers/HLL2315DW/lpd/filter_HLL2315DW \
          --replace /opt "$out/opt" \
          --replace /usr/bin/perl ${lib.getExe perl} \
          --replace "BR_PRT_PATH =~" "BR_PRT_PATH = \"$out/opt/brother/Printers/HLL2315DW/\"; #" \
          --replace "PRINTER =~" "PRINTER = \"HLL2315DW\"; #"

        patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
          $out/opt/brother/Printers/HLL2315DW/lpd/brprintconflsr3
        patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
          $out/opt/brother/Printers/HLL2315DW/lpd/rawtobr3

        for f in \
          $out/opt/brother/Printers/HLL2315DW/cupswrapper/brother_lpdwrapper_HLL2315DW \
          $out/opt/brother/Printers/HLL2315DW/cupswrapper/paperconfigml1 \
        ; do
          wrapProgram $f \
            --prefix PATH : ${
              lib.makeBinPath [
                coreutils
                ghostscript
                gnugrep
                gnused
              ]
            }
        done

        mkdir -p $out/lib/cups/filter/
        ln -s $out/opt/brother/Printers/HLL2315DW/lpd/filter_HLL2315DW $out/lib/cups/filter/brother_lpdwrapper_HLL2315DW

        mkdir -p $out/share/cups/model
        ln -s $out/opt/brother/Printers/HLL2315DW/cupswrapper/brother-HLL2315DW-cups-en.ppd $out/share/cups/model/

        wrapProgram $out/opt/brother/Printers/HLL2315DW/lpd/filter_HLL2315DW \
          --prefix PATH ":" ${
            lib.makeBinPath [
              ghostscript
              a2ps
              file
              gnused
              gnugrep
              coreutils
              which
            ]
          }
      '';

      meta = {
        homepage = "https://www.brother.com/";
        description = "Brother hl-l2315dw printer driver";
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        license = lib.licenses.unfree;
        platforms = lib.platforms.linux;
        downloadPage = "https://support.brother.com/g/b/downloadlist.aspx?c=us&lang=en&prod=hll2315dw_us&os=128";
      };
    };
}
