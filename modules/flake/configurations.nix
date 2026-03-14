let
  module =
    {
      withSystem,
      inputs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.configurations;
    in
    {
      options.configurations = {
        nixos = lib.mkOption {
          type = lib.types.lazyAttrsOf lib.types.deferredModule;
          default = { };
        };
        darwin = lib.mkOption {
          type = lib.types.lazyAttrsOf lib.types.deferredModule;
          default = { };
        };
        home = lib.mkOption {
          type = lib.types.lazyAttrsOf (
            lib.types.submodule {
              options = {
                system = lib.mkOption {
                  type = lib.types.str;
                  description = "The system type for this home-manager configuration.";
                };
                module = lib.mkOption {
                  type = lib.types.deferredModule;
                  default = { };
                };
              };
            }
          );
        };
      };

      config.flake = {
        nixosConfigurations = lib.flip lib.mapAttrs cfg.nixos (
          name: module:
          inputs.nixpkgs.lib.nixosSystem {
            specialArgs = { inherit name; }; # kinda hacky but makes disko module not infinitely recurse
            modules = [
              # the host configuration
              module
              {
                networking.hostName = lib.mkDefault name;
              }
              inputs.home-manager.nixosModules.home-manager
              # internal modules
              inputs.self.modules.nixos.default
              # home manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  sharedModules = lib.singleton inputs.self.modules.homeManager.default;
                };
              }
            ];
          }
        );

        darwinConfigurations = lib.flip lib.mapAttrs cfg.darwin (
          name: module:
          inputs.nix-darwin.lib.darwinSystem {
            modules = [
              # the host configuration
              module
              {
                networking.hostName = lib.mkDefault name;
              }
              inputs.home-manager.darwinModules.home-manager
              # internal modules
              inputs.self.modules.darwin.base
              inputs.self.modules.darwin.style
              # home manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  sharedModules = lib.singleton inputs.self.modules.homeManager.default;
                };
              }
            ];
          }
        );

        homeConfigurations = lib.flip lib.mapAttrs cfg.home (
          name:
          { system, module }:
          inputs.home-manager.lib.homeManagerConfiguration (
            withSystem system (
              { pkgs, ... }:
              {
                inherit pkgs;
                modules = [
                  module
                  {
                    # TODO: get rid of @ in nane - ex. caleb@littleboy becomes caleb
                    home.username = lib.mkDefault name;
                    # TODO: - adapt for non-linux?
                    home.homeDirectory = lib.mkDefault ("/home/" + name);
                  }
                  # standalone specific
                  inputs.stylix.homeModules.stylix
                  inputs.self.modules.homeManager.standalone
                  inputs.self.modules.homeManager.style
                ]
                ++ lib.singleton inputs.self.modules.homeManager.default;
              }
            )
          )
        );

        # checks = lib.pipe config.flake.nixosConfigurations [
        #   (lib.mapAttrsToList (
        #     name: nixos: {
        #       ${nixos.config.nixpkgs.hostPlatform.system} = {
        #         "configurations/nixos/${name}" = nixos.config.system.build.toplevel;
        #       };
        #     }
        #   ))
        #   lib.mkMerge
        # ];
      };
    };
in
{
  # import the module to use it internally
  imports = [
    module
  ];
  # export the module for use in other flake modules
  flake.modules.flake.configurations = module;
}
