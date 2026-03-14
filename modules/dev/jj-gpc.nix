{
  # experimenting with jj-gpc
  flake.modules = {
    nixos.jj-gpc = {
      services.ollama = {
        enable = true;
        loadModels = [
          "phi3" # default for jj-gpc, but can be overridden with --model
        ];
      };
    };

    homeManager.jj-gpc =
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.jj-gpc.override {
            prefix = "gigamonster256";
          })
        ];
      };
  };

  # TODO: dont have to download the models on every reboot
  #   persistence.programs.nixos = {
  #     ollama = {
  #       namespace = "services";
  #       directories = [
  #         # services.ollama.home
  #         {
  #           directory = "/var/lib/ollama";
  #           mode = "0700";
  #         }
  #       ];
  #     };
  #   };
}
