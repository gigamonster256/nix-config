# Installing
- [Install Nix](https://nixos.org/download/)  
- Bootstrap
```bash
nix run --extra-experimental-features "nix-command flakes" --no-write-lock-file github:nix-community/home-manager/ -- --extra-experimental-features "nix-command flakes" --flake "github:gigamonster256/nix-config#$USER@default" switch
```

- Installing nix-darwin
```bash
sudo nix run --inputs-from github:gigamonster256/nix-config nix-darwin#darwin-rebuild -- switch --flake github:gigamonster256/nix-config
```

- Installing home-manager
```bash
nix run --inputs-from github:gigamonster256/nix-config nixpkgs#nh -- home switch github:gigamonster256/nix-config
```
