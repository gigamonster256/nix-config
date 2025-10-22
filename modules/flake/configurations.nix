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
        # nixos configurations
        nixos = lib.mkOption {
          type = lib.types.lazyAttrsOf lib.types.deferredModule;
          default = { };
        };
        # nix-darwin configurations
        darwin = lib.mkOption {
          type = lib.types.lazyAttrsOf lib.types.deferredModule;
          default = { };
        };
        # standalone home-manager configurations
        home = lib.mkOption {
          type = lib.types.lazyAttrsOf (
            lib.types.submodule {
              options.system = lib.mkOption {
                type = lib.types.str;
                description = "The system type for this home-manager configuration.";
              };
              options.module = lib.mkOption {
                type = lib.types.deferredModule;
                default = { };
              };
            }
          );
        };
      };

      config.flake =
        let
          homeManagerSharedModules = [
            inputs.nix-index-database.homeModules.nix-index
            inputs.self.modules.homeManager.base
            inputs.self.modules.homeManager.style
          ];
        in
        {
          nixosConfigurations = lib.flip lib.mapAttrs cfg.nixos (
            name: module:
            lib.nixosSystem {
              modules = [
                # the host configuration
                module
                {
                  _module.args.hostConfig.name = name;
                }
                # external modules
                inputs.nixos-facter-modules.nixosModules.facter
                inputs.disko.nixosModules.disko
                inputs.lanzaboote.nixosModules.lanzaboote
                # internal modules
                config.unify.nixos
                inputs.self.modules.nixos.style
                # probably should be moved/deleted
                inputs.home-manager.nixosModules.home-manager
                # inputs.spicetify-nix.nixosModules.default
                inputs.nix-index-database.nixosModules.nix-index
                # home manager
                (
                  { config, ... }:
                  {
                    home-manager = {
                      useGlobalPkgs = true;
                      # TODO: get rid of this
                      extraSpecialArgs = {
                        systemConfig = config;
                      };
                      sharedModules = homeManagerSharedModules ++ [
                        inputs.self.modules.homeManager.impermanence
                      ];
                    };
                  }
                )
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
                (
                  { config, ... }:
                  {
                    home-manager = {
                      useGlobalPkgs = true;
                      # TODO: get rid of this
                      extraSpecialArgs = {
                        systemConfig = config;
                      };
                      sharedModules = homeManagerSharedModules;
                    };
                  }
                )
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
                  ]
                  ++ homeManagerSharedModules;
                  # pass the system configuration to home-manager modules that need it
                  extraSpecialArgs = {
                    systemConfig = null;
                  };
                }
              )
            )
          );

          # checks =
          #   config.flake.nixosConfigurations
          #   |> lib.mapAttrsToList (
          #     name: nixos: {
          #       ${nixos.config.nixpkgs.hostPlatform.system} = {
          #         "configurations/nixos/${name}" = nixos.config.system.build.toplevel;
          #       };
          #     }
          #   )
          #   |> lib.mkMerge;
        };
    };
in
{
  # import the module to use it internally
  imports = [ module ];
  # export the module for use in other flake modules
  flake.modules.flake.configurations = module;
}
