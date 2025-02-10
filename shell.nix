{
  pkgs ? import <nixpkgs> {},
  additionalShells ? [],
  ...
}:
pkgs.mkShellNoCC {
  NIX_CONFIG = "extra-experimental-features = nix-command flakes ca-derivations";
  nativeBuildInputs = with pkgs; [
    nix
    home-manager
    git

    sops
    ssh-to-age
    gnupg
    age
  ];

  inputsFrom = additionalShells;
}
