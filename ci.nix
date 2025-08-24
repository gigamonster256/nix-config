{
  self,
  lib,
}:
let
  inherit (lib) genAttrs mapAttrs;
  mkSpec =
    system:
    {
      nixos ? [ ],
      darwin ? [ ],
      home ? [ ],
      artifacts ? { },
    }:
    let
      nixosAttrs = genAttrs nixos (
        hostname: self.nixosConfigurations.${hostname}.config.system.build.toplevel
      );
      darwinAttrs = genAttrs darwin (
        hostname: self.darwinConfigurations.${hostname}.config.system.build.toplevel
      );
      homeAttrs = genAttrs home (
        homename: self.packages.${system}.homeConfigurations.${homename}.config.home.activationPackage
      );
    in
    {
      inherit artifacts;
      cachix = nixosAttrs // darwinAttrs // homeAttrs;
    };
  mkCaches = mapAttrs mkSpec;
in
mkCaches {
  x86_64-linux = {
    nixos = [
      # "chnorton-fw" # too big for github actions default runner disk :(
      "littleboy"
    ];
    home = [
      # "caleb@littleboy"
      "chnorton"
    ];
  };
  aarch64-linux = {
    nixos = [ "tinyca" ];
    artifacts = {
      # tinyca-image = self.images.tinyca;
    };
  };
  aarch64-darwin = {
    darwin = [ "chnorton-mbp" ];
    home = [ "caleb@chnorton-mbp" ];
  };
}
