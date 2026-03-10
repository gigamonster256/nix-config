{
  # experimenting with jj-gpc
  unify.modules.jj-gpc = {
    nixos = {
      services.ollama = {
        enable = true;
        loadModels = [
          "phi3" # default for jj-gpc, but can be overridden with --model
        ];
      };
    };

    home =
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
