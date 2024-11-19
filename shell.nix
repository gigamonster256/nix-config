{
  pkgs,
  shellHook,
  ...
}: {
  default = pkgs.mkShell {
    inherit shellHook;
    nativeBuildInputs = with pkgs; [
      nix
      home-manager
      git

      sops
      ssh-to-age
      gnupg
      age
    ];
  };
}
