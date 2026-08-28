{
  nixpkgs.allowedUnfreePackages = [
    "omnidrive-base-firmware"
  ];

  packages.omnidrive =
    {
      lib,
      stdenv,
      fetchFromGitHub,
      fetchzip,
      writeText,
      cmake,
      ninja,
      armips,
      python3,
      pkgsCross,
    }:
    let
      firmware = stdenv.mkDerivation {
        name = "omnidrive-base-firmware";

        src = fetchzip {
          url = "https://archive.org/compress/omnidrive-stock-files";
          extension = "zip";
          stripRoot = false;
          sha256 = "sha256-g6f9YAqCUh85KAnzbOB32MQTa98JLUOsLWidnMhQTxU=";
        };

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/share/omnidrive-base-firmware
          cp -r $src/*.bin $out/share/omnidrive-base-firmware/

          runHook postInstall
        '';

        dontFixup = true;

        meta.license = lib.licenses.unfree;
      };

      hashes = writeText "firmware-hashes" ''
        9C48677B155154D24A3B95A32B4A29CA02FF40B3 HL-DT-ST_BD-RE_BU40N_1.00.bin
        F8DF5B579F25DA8D4E5AA5EF79F3005DAC5EB8C7 ASUS_BW-16D1HT_3.02.bin
      '';

      pythonEnv = python3.withPackages (ps: [ ps.pycryptodome ]);

      armips-master = armips.overrideAttrs (prev: {
        version = "0.11.0-unstable-2026-08-01";

        src = fetchFromGitHub {
          inherit (prev.src) owner repo;
          rev = "62adab4ef30da765f5cf22a451eb08a59c54dc8b";
          fetchSubmodules = true;
          hash = "sha256-321Z/O68jLJIbbSVBi2eUWJXbmgxX7mqO6tjILCaN4M=";
        };

        # master's CMakeLists.txt already requires >= 3.10 and builds with C++17,
        # so nixpkgs' postPatch substitutions no longer apply
        postPatch = "";
      });
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "omnidrive";
      version = "1.0.4";

      src = fetchFromGitHub {
        owner = "RibShark";
        repo = "OmniDrive";
        tag = "v${finalAttrs.version}";
        sha256 = "sha256-PJ1pfOze0hfQY8zrBatT/Lu5/23tzF/I/qt6Rt30trk=";
      };

      hardeningDisable = [ "all" ];

      nativeBuildInputs = [
        cmake
        ninja
        armips-master
        pythonEnv
        pkgsCross.arm-embedded.stdenv.cc
      ];

      preConfigure = ''
        cp ${firmware}/share/omnidrive-base-firmware/* ./firmware/

        # check hashes
        pushd firmware
        sha1sum -c ${hashes} || (echo "ERROR: firmware hashes do not match" && exit 1)
        popd

        # store copies are read-only, but armips opens them read-write
        chmod +w firmware/*.bin
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share/omnidrive
        cp ../patched_firmware/*.bin $out/share/omnidrive/

        runHook postInstall
      '';

      dontFixup = true;

      passthru = {
        inherit firmware;
      };

      meta = {
        description = "Firmware modification for MediaTek MT1959-based optical disc drives";
        homepage = "https://github.com/RibShark/OmniDrive";
        license = lib.licenses.gpl3Plus;
      };
    });
}
