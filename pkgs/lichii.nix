{
  autoUpdatePackages.lichii = {
    extraArgs = [
      "--subpackage"
      "nxformat"
    ];
  };

  packages.lichii =
    {
      lib,
      llvmPackages_23,
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
      nxformat,
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
      version = "160";

      src = fetchFromGitHub {
        owner = "zortos293";
        repo = "Lichii";
        tag = "build-${finalAttrs.version}";
        hash = "sha256-vAQMhWGBWMwLsxbUY1hbXsDfyvd65JsCDZ/d52tZGUc=";
      };

      strictDeps = true;
      doCheck = true;
      # Makes list attributes (cmakeFlags) real bash arrays, so flags containing
      # spaces stay a single argument in the CMake hook.
      __structuredAttrs = true;

      patches = [
        # Clang-only structured-binding shadow (not covered by an upstream PR).
        (fetchpatch2 {
          name = "lichii-shadow-pipeline-cache.patch";
          url = "https://github.com/gigamonster256/Lichii/commit/421d9347c1745e342c45c5bf6bc6e40b0a694f99.patch?full_index=1";
          hash = "sha256-t2E52ZCnOMbOyW5yZjGFEpvZCj13JpemA5E3/PV9LkM=";
          includes = [ "src/video_core/renderer_vulkan/vk_pipeline_cache.cpp" ];
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

      passthru = {
        inherit nxformat;
      };

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
