{pkgs,config, ...}: {
  programs.jujutsu = {
    enable = true;
    package = pkgs.unstable.jujutsu;
    settings = {
      user = {
        name = config.programs.git.userName;
        email = config.programs.git.userEmail;
        ui.merge-editor = ":builtin";
      };
    };
  };
}
