{
  lib,
  fetchgit,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "recursive-cpu-usage";
  version = "alpha";

  src = fetchgit {
    url = "https://codeberg.org/FliegendeWurst/recursive-cpu-usage.git";
    rev = "e6fd645a593cdceac9f5fe137dbf4bf2392f8056";
    hash = "sha256-HSRZQ5dlJ+9SKGztGfMcwh0X/9U1lJhMtbPi7SVXjNE=";
  };

  cargoHash = "sha256-vcGSOTS8YDMP8DYGJohCxHNvfezqZdcXN7x5blo5yGk=";

  meta = {
    description = "Simple utility to get the CPU used by a process and all of its children / grand-children / ...";
    homepage = "https://codeberg.org/FliegendeWurst/recursive-cpu-usage";
    license = lib.licenses.unlicense;
  };
}
