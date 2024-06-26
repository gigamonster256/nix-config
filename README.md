# Installing
- [Install Nix](https://nixos.org/download/)  
- Bootstrap
```bash
nix run --extra-experimental-features "nix-command flakes" --no-write-lock-file github:nix-community/home-manager/ -- --extra-experimental-features "nix-command flakes" --flake "github:gigamonster256/nix-config#$USER@default" switch
```
