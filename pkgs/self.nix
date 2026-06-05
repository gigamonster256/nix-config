{ inputs, ... }:
{
  packages.manga-dl = import (inputs.manga-dl + /package.nix);
}
