{
  nixpkgs.allowedUnfreePackages = [
    "cups-brother-hll2315dw"
  ];

  packages.cups-brother-hll2315dw =
    {
      lib,
      fetchurl,
      pkgsi686Linux,
      autoPatchelfHook,
      makeWrapper,
      dpkg,
      perl,
      coreutils,
      gnugrep,
      gnused,
      ghostscript,
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
    pkgsi686Linux.stdenv.mkDerivation {
      pname = "cups-brother-hll2315dw";
      inherit version;

      nativeBuildInputs = [
        autoPatchelfHook
        makeWrapper
        dpkg
      ];

      dontUnpack = true;

      installPhase = ''
        mkdir -p $out
        dpkg-deb -x ${cupsdeb} $out
        dpkg-deb -x ${lprdeb} $out

        basedir=$out/opt/brother/Printers/HLL2315DW

        rm -rf $out/{etc,usr,var}
        rm -f $basedir/inf/setupPrintcap
        rm -f $basedir/cupswrapper/paperconfigml1

        cupsfilter=$basedir/cupswrapper/brother_lpdwrapper_HLL2315DW
        substituteInPlace $cupsfilter \
          --replace-fail /usr/bin/perl ${lib.getExe perl} \
          --replace-fail "basedir = \`readlink \$0\`" "basedir = \"$basedir\"" \
          --replace-fail "PRINTER =~ s/\\///g" "PRINTER=\"HLL2315DW\"" \
          --replace-fail "\$TEMPRC\`;" "\$TEMPRC\ && chmod 0600 \$TEMPRC\`;"
        wrapProgram $cupsfilter \
          --prefix PATH : ${
            lib.makeBinPath [
              coreutils
              gnugrep
            ]
          }

        lpdfilter=$basedir/lpd/filter_HLL2315DW
        substituteInPlace $lpdfilter \
          --replace-fail /usr/bin/perl ${lib.getExe perl} \
          --replace-fail "PRINTER =~ s/\.pl$//" "PRINTER=\"HLL2315DW\"" \
          --replace-fail "BR_PRT_PATH = Cwd::realpath (\$0)" "BR_PRT_PATH = \"$basedir\"" \
          --replace-fail "\`which gs\`" "\"gs\""
        wrapProgram $lpdfilter \
          --prefix PATH : ${
            lib.makeBinPath [
              coreutils
              gnugrep
              gnused
              ghostscript
            ]
          }

        mkdir -p $out/lib/cups/filter/
        ln -s $out/opt/brother/Printers/HLL2315DW/cupswrapper/brother_lpdwrapper_HLL2315DW $out/lib/cups/filter/brother_lpdwrapper_HLL2315DW

        mkdir -p $out/share/cups/model
        ln -s $out/opt/brother/Printers/HLL2315DW/cupswrapper/brother-HLL2315DW-cups-en.ppd $out/share/cups/model/
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
