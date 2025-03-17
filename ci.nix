{self}: let
  nixosFor = hostname: self.nixosConfigurations.${hostname}.config.system.build.toplevel;
  darwinFor = hostname: self.darwinConfigurations.${hostname}.config.system.build.toplevel;
  homeForSystem = system: hostname: self.packages.${system}.homeConfigurations.${hostname}.config.home.activationPackage;
in {
  x86_64-linux = let
    homeFor = homeForSystem "x86_64-linux";
  in {
    littleboy = nixosFor "littleboy";
    littleboy-home = homeFor "caleb@littleboy";
    chnorton-home = homeFor "chnorton";
  };
  aarch64-linux = {
    tinyca = nixosFor "tinyca";
    tinyca-image = self.images.tinyca;
  };
  aarch64-darwin = let
    homeFor = homeForSystem "aarch64-darwin";
  in {
    macbook = darwinFor "chnorton-mbp";
    macbook-home = homeFor "caleb@chnorton-mbp";
  };
}
