{
  packages.nixify-bootstrap =
    {
      writeShellApplication,
      openssh,
      nixos-anywhere,
    }:
    writeShellApplication {
      name = "nixify-bootstrap";
      runtimeInputs = [
        openssh
        nixos-anywhere
      ];
      text = ''
        # Script to install a host using nixos-anywhere and fetch its facter data
        # Usage: nixify-bootstrap <host-name> [facter-output-dir]

        if [ $# -lt 1 ] || [ $# -gt 2 ]; then
            echo "Usage: nixify-bootstrap <host-name> [facter-output-dir]"
            echo "Example: nixify-bootstrap wyse-DX"
            echo "Example: nixify-bootstrap wyse-DX hosts/wyse/DX"
            exit 1
        fi

        HOST_NAME="$1"

        # Use provided output directory or default to hosts/<host-name>
        if [ $# -eq 2 ]; then
            HOST_DIR="$2"
        else
            HOST_DIR="hosts/$HOST_NAME"
        fi

        # Check if host directory exists
        if [ ! -d "$HOST_DIR" ]; then
            echo "Error: Host directory does not exist: $HOST_DIR"
            exit 1
        fi

        FACTER_JSON="$HOST_DIR/facter.json"

        echo "Connecting to bootstrap.local..."
        echo "Running nixos-anywhere to generate hardware configuration..."

        # Run nixos-anywhere with --generate-hardware-config to fetch facter data
        nixos-anywhere \
          --generate-hardware-config nixos-facter "$FACTER_JSON" \
          --flake ".#$HOST_NAME" \
          --target-host root@bootstrap.local

        echo "Host installed"
      '';
    };
}
