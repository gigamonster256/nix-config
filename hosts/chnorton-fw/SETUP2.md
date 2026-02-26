added more boot partition space

git clone https://github.com/gigamonster256/nix-config.git cd nix-config

sudo nix run --extra-experimental-features 'nix-command flakes' --inputs-from
github:gigamonster256/nix-config nixpkgs#disko -- --mode destroy,format,mount
--flake github:gigamonster256/nix-config#chnorton-fw

make pass file to copy-paste into disko prompt

## setup secrets

pre-generate ssh host keys sudo mkdir -p /mnt/persist/etc/ssh sudo ssh-keygen -t
ed25519 -f /mnt/persist/etc/ssh/ssh_host_ed25519_key -N ''

get age key for it

sudo nix run --extra-experimental-features 'nix-command flakes' --inputs-from
github:gigamonster256/nix-config nixpkgs#ssh-to-age -- -i
/mnt/persist/etc/ssh/ssh_host_ed25519_key.pub

place into .sops.yaml

re-encrypt using gpg key

nix shell --extra-experimental-features 'nix-command flakes' --inputs-from
github:gigamonster256/nix-config nixpkgs#gnupg nixpkgs#pinentry-curses

nix shell --extra-experimental-features 'nix-command flakes' --inputs-from
github:gigamonster256/nix-config nixpkgs#gnupg gpg --recv-keys
483a112b3567c4f0df8974e1d776f5702d7e83ab

pkill gpg-agent gpg-agent --pinentry-program
/nix/store/00kxa0nbm6hpvqd5y6z9dmn09sbyjv0i-pinentry-curses-1.3.2/bin/pinentry
--daemon (path from $PATH)

mix run --extra-experimental-features 'nix-command flakes' --inputs-from
github:gigamonster256/nix-config nixpkgs#sops updatekeys
hosts/chnorton-fw/secrets.yaml modules/secrets/secrets.yaml

comment out secure-boot and systemIdentity (delete the bad module too)

cp nix-config to /mnt/persist/

mv nix-config /mnt/persist/home/caleb/git/
