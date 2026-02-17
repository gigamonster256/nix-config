{
  packages.dakota =
    {
      lib,
      stdenv,
      fetchurl,
      cmake,
      gfortran,
      perl,
      python3,
      lapack,
      boost,
      blas,
      mpi,
      trilinos,
      withMPI ? false,
      bundledTrilinos ? false,
    }:
    let
      trilinosWithROL = (trilinos.override { inherit withMPI; }).overrideAttrs (oldAttrs: {
        cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
          "-DTrilinos_ENABLE_ROL=ON"
        ];
      });
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "dakota";
      version = "6.23.0";

      src = fetchurl {
        url = "https://github.com/snl-dakota/dakota/releases/download/v${finalAttrs.version}/dakota-${finalAttrs.version}-public-src-cli.tar.gz";
        hash = "sha256-+EYaENRgMzpTmj5tMZ1FvUShjQbIYq2CBClM+0GKyNw=";
      };

      nativeBuildInputs = [
        cmake
        gfortran
        perl
        python3
        lapack
        boost
        blas
      ]
      ++ lib.optional withMPI mpi
      ++ lib.optional (!bundledTrilinos) trilinosWithROL;

      hardeningDisable = [ "format" ];

      cmakeFlags = [
        "-DCMAKE_C_FLAGS=-std=gnu89" # too many arguments (functions forward declared as fn() even if they take args)
      ]
      ++ lib.optional withMPI "-DDAKOTA_HAVE_MPI:BOOL=TRUE"
      ++ lib.optional (!bundledTrilinos) "-DTrilinos_DIR=${trilinosWithROL}/lib/cmake/Trilinos";

      meta = {
        description = "Multilevel Parallel Object-Oriented Framework for Design Optimization, Parameter Estimation, Uncertainty Quantification, and Sensitivity Analysis";
        homepage = "https://dakota.sandia.gov/";
        license = lib.licenses.lgpl21Only;
        mainProgram = "dakota";
        platforms = lib.platforms.linux;
      };
    });
}
