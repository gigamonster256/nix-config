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
            inputs.self.modules.homeManager.default
            inputs.self.modules.homeManager.style
          ];
        in
        {
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
{ inputs, ... }:
{
  # import the module to use it internally
  imports = [
    module
    inputs.unify.flakeModule
  ];
  # export the module for use in other flake modules
  flake.modules.flake.configurations = module;
}
