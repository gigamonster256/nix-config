# Chnorton FW
Framework 13 Ryzen AI 5 340

## Stage 1 - Initial Setup
Keyboard unsupported using the NixOS 24.11 installer I had on hand
No wifi adapter either... off to a rough start

After finding ethernet and a usb keyboard, I cloned my nix-config repo at c14c32d9 and added chnorton-fw to the flake.nix (without home-manager) and created a folder in `hosts`
```bash
git clone https://github.com/gigamonster256/nix-config.git && cd nix-config
mkdir hosts/chnorton-fw
```

### nixos-facter

```bash
sudo nix run --extra-experimental-features 'nix-command flakes' --inputs-from github:gigamonster256/nix-config nixpkgs#nixos-facter -- -o hosts/chnorton-fw/facter.json
sudo chown nixos:users hosts/chnorton-fw/facter.json
```

removed usb keyboard from the report

nix fmt without nix-command and flakes enabled
```bash
nix fmt --extra-experimental-features 'nix-command flakes' --accept-flake-config
```

### disko

pretty simple - copied the config from littleboy, set the disk id from the report, and set the swapfile size to match RAM (64GB)

I then partitioned the drive with
```bash
sudo nix run --extra-experimental-features 'nix-command flakes' --inputs-from github:gigamonster256/nix-config nixpkgs#disko -- --mode destroy,format,mount hosts/chnorton-fw/disko.nix
```

and set the luks password


### minimal nixos-install

Next, I set up a minimal nixos config with lanzabote disabled (for now), backed up all the changes I made and installed it
```bash
git add .
nix flake --extra-experimental-features 'nix-command flakes' --accept-flake-config check
sudo nixos-install --flake .#chnorton-fw --no-root-password --no-channel-copy
```

and rebooted into the new system

## Stage 2 - Securing the System

### setting up secrets

I created ssh keys

```bash
sudo ssh-keygen -t ed25519 -f /persist/etc/ssh/ssh_host_ed25519_key -N ''
```

added the public age keys to the .sops.yaml file in the root of the repo
```bash
sudo nix run nixpkgs#ssh-to-age -- -i /persist/etc/ssh/ssh_host_ed25519_key.pub
```

and then re-encrypted the secrets (using my yubikey to add the age key)
```bash
nix run nixpkgs#sops updatekeys hosts/chnorton-fw/secrets.yaml hosts/modules/secrets.yaml
```

### enabling secure boot

create the keys

```bash
sudo nix run nixpkgs#sbctl create-keys
```

then rebuild the system with secrets and lanzaboote enabled
```bash
sudo nixos-rebuild switch --flake .
```

verify the kernel is signed
```bash
sudo nix run nixpkgs#sbctl verify
```

enroll keys (must have cleared keys in framework bios)
```bash
sudo nix run nixpkgs#sbctl enroll-keys
```

and reboot into the new signed kernel (enabling secure boot in the bios)
check with
```bash
bootctl status
```

### enrolling in tpm2 unlock

now that the boot chain is signed, we can enroll the luks partition in tpm2 unlock
```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7+12 --wipe-slot=tpm2 <luks-partition>
```

also fill in the pcr 15 value to protect against identity attacks
```bash
systemd-analyze pcrs 15 --json=short
```
