{
  packages.add-sops-host =
    {
      writeShellApplication,
      ssh-to-age,
      openssh,
      coreutils,
      yq-go,
    }:
    writeShellApplication {
      name = "add-sops-host";
      runtimeInputs = [
        ssh-to-age
        openssh
        coreutils
        yq-go
      ];
      text = ''
        usage() {
            echo "Usage: add-sops-host <ip> <hostname> <secrets_path>"
            echo ""
            echo "Arguments:"
            echo "  ip           - IP address of the host to scan"
            echo "  hostname     - Hostname to use as the anchor name in .sops.yaml"
            echo "  secrets_path - Path to the secrets.yaml file (relative to repo root)"
            echo ""
            echo "Example:"
            echo "  add-sops-host 192.168.1.100 myhost hosts/myhost/secrets.yaml"
            exit 1
        }

        if [ $# -ne 3 ]; then
            usage
        fi

        IP="$1"
        HOSTNAME="$2"
        SECRETS_PATH="$3"

        SOPS_FILE=".sops.yaml"

        if [ ! -f "$SOPS_FILE" ]; then
            echo "Error: $SOPS_FILE not found in current directory"
            echo "Please run this script from the repository root"
            exit 1
        fi

        echo "Scanning SSH host key from $IP..."

        # Get the ed25519 host key
        if ! KEYSCAN_OUTPUT=$(ssh-keyscan -t ed25519 "$IP" 2>/dev/null) || [ -z "$KEYSCAN_OUTPUT" ]; then
            echo "Error: ssh-keyscan failed to connect to $IP"
            exit 1
        fi

        # Extract the key (filter out comments)
        SSH_KEY=$(echo "$KEYSCAN_OUTPUT" | grep -v '^#')
        if [ -z "$SSH_KEY" ]; then
            echo "Error: Could not retrieve ed25519 SSH key from $IP"
            exit 1
        fi

        AGE_KEY=$(echo "$SSH_KEY" | ssh-to-age)
        if [ -z "$AGE_KEY" ]; then
            echo "Error: Could not convert SSH key to age key"
            exit 1
        fi

        echo "Age key: $AGE_KEY"

        # Check if host already exists using yq (check if anchor exists)
        if yq -e ".keys[1][] | select(anchor == \"$HOSTNAME\")" "$SOPS_FILE" &>/dev/null; then
            echo "Error: Host '$HOSTNAME' already exists in $SOPS_FILE"
            exit 1
        fi

        # Create a backup
        cp "$SOPS_FILE" "$SOPS_FILE.bak"

        echo "Adding host '$HOSTNAME' to .sops.yaml..."

        # Add host to keys[1] (the hosts array) with anchor
        yq -i "(.keys[1]) += [\"$AGE_KEY\" | . anchor = \"$HOSTNAME\"]" "$SOPS_FILE"

        # Add the new creation rule with placeholder values
        yq -i ".creation_rules += [{\"path_regex\": \"''${SECRETS_PATH}\$\", \"key_groups\": [{\"age\": [\"placeholder\"], \"pgp\": [\"placeholder\"]}]}]" "$SOPS_FILE"

        # Set the alias references for age and pgp keys
        yq -i ".creation_rules[-1].key_groups[0].age[0] alias = \"$HOSTNAME\"" "$SOPS_FILE"
        yq -i ".creation_rules[-1].key_groups[0].pgp[0] alias = \"caleb\"" "$SOPS_FILE"

        echo "Successfully added host '$HOSTNAME' to $SOPS_FILE"
        echo ""
        echo "Host anchor: &$HOSTNAME $AGE_KEY"
        echo "Secrets path: $SECRETS_PATH"
        echo ""
        echo "Backup saved to $SOPS_FILE.bak"
        echo ""
        echo "You may want to create the secrets file:"
        echo "  mkdir -p $(dirname "$SECRETS_PATH")"
        echo "  sops $SECRETS_PATH"
      '';
    };
}
