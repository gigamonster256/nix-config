{
  self,
  lib,
}: let
  mkSpec = system: {
    nixos ? [],
    darwin ? [],
    home ? [],
    artifacts ? {},
  }: let
    nixosAttrs = lib.genAttrs nixos (hostname: self.nixosConfigurations.${hostname}.config.system.build.toplevel);
    darwinAttrs = lib.genAttrs darwin (hostname: self.darwinConfigurations.${hostname}.config.system.build.toplevel);
    homeAttrs = lib.genAttrs home (homename: self.packages.${system}.homeConfigurations.${homename}.config.home.activationPackage);
  in {
    inherit artifacts;
    cachix = nixosAttrs // darwinAttrs // homeAttrs;
  };
  mkCaches = lib.mapAttrs mkSpec;
in
  mkCaches {
    x86_64-linux = {
      nixos = ["littleboy"];
      home = [
        # "caleb@littleboy"
        "chnorton"
      ];
    };
    aarch64-linux = {
      nixos = ["tinyca"];
      artifacts = {
        # tinyca-image = self.images.tinyca;
      };
    };
    aarch64-darwin = {
      darwin = ["chnorton-mbp"];
      home = ["caleb@chnorton-mbp"];
    };
  }
