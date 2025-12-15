# Bootstrap Host

A lightweight NixOS image designed for provisioning new machines over the network.

## Purpose

The bootstrap host provides a minimal NixOS environment that:

- Boots on target hardware (via USB/ISO/NETBOOT)
- Advertises itself as `bootstrap.local` via Avahi/mDNS
- Enables SSH access for remote provisioning
- Serves as a target for `nixos-anywhere` to install the final system

## Usage

### 1. Build the Bootstrap ISO

```bash
nix build .#images.bootstrap
```

The ISO will be available at `./result/iso/`.

### 2. Boot the Target Machine

Flash the ISO to a USB drive and boot the target machine from it. The machine will automatically:

- Start the SSH daemon
- Publish itself as `bootstrap.local` on the local network

### 3. Run the Provisioning Script

Use the `nixify-bootstrap` script to install the target configuration:

```bash
# Install a host with default directory structure
nix run .#nixify-bootstrap <host-name>

# Example: Install wyse-DX configuration
nix run .#nixify-bootstrap wyse-DX

# Specify a custom host directory for the facter.json output
nix run .#nixify-bootstrap wyse-DX hosts/wyse/DX
```

The script will:

1. Connect to `bootstrap.local` via SSH
2. Generate hardware configuration using `nixos-facter`
3. Install the specified NixOS configuration using `nixos-anywhere`

## Configuration Details

- **Platform**: x86_64-linux
- **SSH Access**: Root login enabled with pre-configured SSH keys
- **Network Discovery**: Avahi publishes the hostname `bootstrap.local`
- **Minimal Footprint**: Documentation disabled for smaller closure size

## Netboot Server Module

For environments where USB booting is impractical, the `netbootstrapper` module configures a [Pixiecore](https://github.com/danderson/netboot) server to PXE boot machines directly into the bootstrap environment.

### Enabling Netboot

Add the module to any NixOS host that should serve as a netboot server:

```nix
{
  imports = [ config.unify.modules.netbootstrapper.nixos ];
}
```

This will:

- Enable the Pixiecore service
- Open the necessary firewall ports
- Serve the bootstrap kernel and initrd over the network

### Network Booting a Machine

1. Ensure the target machine is on the same network as the netboot server
2. Configure the target machine to boot from the network (PXE boot)
3. The machine will boot into the bootstrap environment automatically
