{ inputs, self, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];
  flake.flakeModules = self.modules.flake;
  flake.nixosModules = self.modules.nixos;
  flake.homeModules = self.modules.homeManager;
  flake.darwinModules = self.modules.darwin;
}
