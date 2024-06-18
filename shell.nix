{pkgs, ...}: {
  default = pkgs.mkShell {
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
