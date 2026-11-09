{
  autoUpdatePackages.lichii = { };

  packages.lichii =
    {
      lib,
      llvmPackages_23,
      rustPlatform,
      fetchFromGitHub,
      fetchpatch2,
      cmake,
      ninja,
      pkg-config,
      python3,
      glslang,
      boost,
      catch2_3,
      cpp-jwt,
      cubeb,
      eden,
      enet,
      ffmpeg-headless,
      fmt,
      frozen-containers,
      gamemode,
      httplib,
      kdePackages,
      libopus,
      libusb1,
      lz4,
      nlohmann_json,
      oaknut,
      openssl,
      pipewire,
      qt6,
      sdl3,
      simpleini,
      sirit,
      spirv-headers,
      spirv-tools,
      vulkan-headers,
      vulkan-loader,
      vulkan-memory-allocator,
      vulkan-utility-libraries,
      wrapGAppsHook3,
      xbyak,
      xxhash,
      zlib,
      zstd,
      withPgo ? true,
    }:
    let
      nxformatVersion = "1.0.1";
      nxPlatform = if llvmPackages_23.stdenv.hostPlatform.isAarch64 then "linux-arm64" else "linux-x64";

      # Lichii normally downloads a prebuilt nxformat release at configure time.
      # Build the C API from source instead so the package stays offline and
      # native to the target platform.
      nxformatSrc = fetchFromGitHub {
        owner = "fab918";
        repo = "nxformat";
        tag = "V${nxformatVersion}";
        hash = "sha256-QL0QDyoTUFn8BHgrkdyWq4D9h0yymzg7aKUZQHVvqgM=";
      };

      nxformat = rustPlatform.buildRustPackage {
        pname = "nxformat";
        version = nxformatVersion;
        src = nxformatSrc;

        cargoHash = "sha256-O5Xk352NNup99sM+HKOdbQ2fYSCh22ug4kwnSKytOi8=";
        cargoRoot = "ffi";
        buildAndTestSubdir = "ffi";
        dontCargoInstall = true;

        nativeBuildInputs = [ python3 ];

        installPhase = ''
          runHook preInstall

          libdir="$(dirname "$(find target -name libnxformat.so -print -quit)")"
          python3 tools/package_release.py \
            --platform ${nxPlatform} \
            --version "${nxformatVersion}" \
            --lib-dir "$libdir" \
            --out dist-release

          mkdir -p $out
          tar -xzf "dist-release/nxformat-${nxformatVersion}-${nxPlatform}.tar.gz" -C $out

          runHook postInstall
        '';

        meta = {
          description = "Library for reading and writing .nx game archives";
          homepage = "https://github.com/fab918/nxformat";
          license = lib.licenses.mit;
          platforms = lib.platforms.linux;
        };
      };

      zbicSrc = fetchFromGitHub {
        owner = "kinnay";
        repo = "zbic";
        rev = "11b08f2712264bbed731545085cbd9702096ceb7";
        hash = "sha256-pHvxa1gkUvQo6mUgmLWtj1kcu01BLdGmttZyb8ZAj/o=";
      };

      reshadeSrc = fetchFromGitHub {
        owner = "crosire";
        repo = "reshade";
        tag = "v6.8.0";
        hash = "sha256-K6QC7CLqy8M318n9WbuqGvcRF9g9abvDD/xbr7T+nXo=";
      };
    in
    llvmPackages_23.stdenv.mkDerivation (finalAttrs: {
      pname = "lichii";
      version = "130";

      src = fetchFromGitHub {
        owner = "zortos293";
        repo = "Lichii";
        tag = "build-${finalAttrs.version}";
        hash = "sha256-L9EzKtqzAgRy5Ci8iqbOjmHVZiheNgC/YKag+5srI2E=";
      };

      strictDeps = true;
      doCheck = true;
      # Makes list attributes (cmakeFlags) real bash arrays, so flags containing
      # spaces stay a single argument in the CMake hook.
      __structuredAttrs = true;

      patches = [
        # u64 ticks shadowed ThreadTicks ticks in OnPresent, breaking -Werror=shadow.
        (fetchpatch2 {
          name = "nx2-stutter-trace-shadowing.patch";
          url = "https://github.com/zortos293/Lichii/commit/8e1523515ac28b2cbefe00511c8246e63dfcde71.patch?full_index=1";
          hash = "sha256-FDOAfyTCzzg0xmZMEQBzmGP6Dzwbs5FPIR/WWIE5VM8=";
          includes = [ "src/video_core/nx2_stutter_trace.cpp" ];
        })
        # Clang-only structured-binding shadow (not covered by an upstream PR).
        (fetchpatch2 {
          name = "lichii-shadow-pipeline-cache.patch";
          url = "https://github.com/gigamonster256/Lichii/commit/421d9347c1745e342c45c5bf6bc6e40b0a694f99.patch?full_index=1";
          hash = "sha256-t2E52ZCnOMbOyW5yZjGFEpvZCj13JpemA5E3/PV9LkM=";
          includes = [ "src/video_core/renderer_vulkan/vk_pipeline_cache.cpp" ];
        })
        # Keep the randomized test order from leaking a debug rejection into the
        # shader cache v2 test.
        (fetchpatch2 {
          name = "lichii-test-rejection-isolation.patch";
          url = "https://github.com/gigamonster256/Lichii/commit/b8bf4c863e9fb1f93bc1c30fc5cf94d52d6351b6.patch?full_index=1";
          hash = "sha256-tgeRXanDXONS+PlVr25KrG/NIE2KC3QM/DlFu5Pc0sM=";
          includes = [ "src/tests/video_core/shader_invalidation.cpp" ];
        })
      ];

      nativeBuildInputs = [
        cmake
        ninja
        glslang
        pkg-config
        python3
        qt6.qttools
        qt6.wrapQtAppsHook
        wrapGAppsHook3
      ];

      buildInputs = [
        boost
        catch2_3
        cpp-jwt
        cubeb
        enet
        ffmpeg-headless
        fmt
        frozen-containers
        gamemode
        httplib
        kdePackages.quazip
        libopus
        libusb1
        lz4
        nlohmann_json
        oaknut
        openssl
        qt6.qtbase
        qt6.qtmultimedia
        qt6.qtwayland
        qt6.qtcharts
        qt6.qtwebengine
        sdl3
        simpleini
        sirit
        spirv-headers
        spirv-tools
        vulkan-headers
        vulkan-memory-allocator
        vulkan-utility-libraries
        xbyak
        zlib
      ];

      cmakeFlags = [
        # Use the packaged dependencies instead of downloading them with CPM.
        (lib.cmakeBool "CPMUTIL_FORCE_SYSTEM" true)

        # These are always built from source upstream, so point CPM at the
        # sources we already fetched instead of letting it hit the network.
        (lib.cmakeFeature "zstd_CUSTOM_DIR" "${zstd.src}")
        (lib.cmakeBool "zbic_FORCE_BUNDLED" true)
        (lib.cmakeFeature "zbic_CUSTOM_DIR" "${zbicSrc}")
        (lib.cmakeBool "xxhash_FORCE_BUNDLED" true)
        (lib.cmakeFeature "xxhash_CUSTOM_DIR" "${xxhash.src}")
        (lib.cmakeBool "reshade_FORCE_BUNDLED" true)
        (lib.cmakeFeature "reshade_CUSTOM_DIR" "${reshadeSrc}")

        (lib.cmakeFeature "YUZU_TZDB_PATH" "${eden.nx_tzdb}")
        (lib.cmakeFeature "LICHII_NXFORMAT_ROOT" "${nxformat}")

        # Optional features
        (lib.cmakeBool "YUZU_USE_QT_WEB_ENGINE" true)
        (lib.cmakeBool "YUZU_USE_QT_MULTIMEDIA" true)
        (lib.cmakeBool "YUZU_INSTALL_UDEV_RULES" true)
      ]
      ++ lib.optionals withPgo [
        # Same flags as upstream's Linux PGO release job. The profile ships in the
        # source tree (eglantine.profdata).
        (lib.cmakeFeature "CMAKE_C_FLAGS" "-fprofile-use=${finalAttrs.src}/eglantine.profdata -Wno-backend-plugin -Wno-profile-instr-unprofiled -Wno-profile-instr-out-of-date")
        (lib.cmakeFeature "CMAKE_CXX_FLAGS" "-fprofile-use=${finalAttrs.src}/eglantine.profdata -Wno-backend-plugin -Wno-profile-instr-unprofiled -Wno-profile-instr-out-of-date")
      ];

      qtWrapperArgs = [
        "--prefix"
        "LD_LIBRARY_PATH"
        ":"
        "${placeholder "out"}/lib/lichii"
        "--prefix"
        "LD_LIBRARY_PATH"
        ":"
        (lib.makeLibraryPath [
          pipewire
          vulkan-loader
        ])
      ];

      meta = {
        description = "Experimental Nintendo Switch 2 emulator derived from Eden and yuzu";
        homepage = "https://github.com/zortos293/Lichii";
        downloadPage = "https://github.com/zortos293/Lichii/releases";
        license = lib.licenses.gpl3Plus;
        mainProgram = "lichii";
        maintainers = [ lib.maintainers.gigamonster256 ];
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
    });
}
