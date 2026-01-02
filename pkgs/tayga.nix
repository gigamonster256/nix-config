{
  packages.tayga =
    {
      lib,
      stdenv,
      fetchFromGitHub,
    }:
    stdenv.mkDerivation (finalAttrs: {
      pname = "tayga";
      version = "0.9.6";
      src = fetchFromGitHub {
        owner = "apalrd";
        repo = "tayga";
        tag = finalAttrs.version;
        hash = "sha256-OsF2RqZzDvf8FMLHN6YAKvWfFgAIQfVkbBTC8hjf2dU=";
      };

      makeFlags = [
        "prefix=${placeholder "out"}"
        "WITH_SYSTEMD=1"
        # where should the systemd service file and config go?
        "sysconfdir=${placeholder "out"}/lib"
      ];

      meta = {
        description = "Out-of-kernel stateless NAT64 implementation for Linux and FreeBSD";
        homepage = "https://github.com/apalrd/tayga";
        license = lib.licenses.gpl2Only;
      };
    });
}
