{lib, ...}: {
  programs.git = let
    inherit (lib) mkDefault;
  in {
    userName = mkDefault "Caleb Norton";
    userEmail = mkDefault "n0603919@outlook.com";
    aliases = {
      exec = mkDefault "!exec ";
    };
  };
}
