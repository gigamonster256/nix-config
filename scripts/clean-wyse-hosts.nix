{
  packages.clean-wyse-hosts =
    {
      writeShellApplication,
    }:
    writeShellApplication {
      name = "clean-wyse-hosts";
      text = ''
        wait_for_host() {
            local HOST="$1"
            local TIMEOUT=120
            local ELAPSED=0
            echo "Waiting for $HOST to come back online..."
            while [ $ELAPSED -lt $TIMEOUT ]; do
                if ssh -o ConnectTimeout=5 "root@$HOST.penguin" "echo ok" 2>/dev/null; then
                    echo "$HOST is back online."
                    return 0
                fi
                sleep 5
                ELAPSED=$((ELAPSED + 5))
            done
            echo "Warning: $HOST did not come back online within ''${TIMEOUT}s"
            return 1
        }

        clean_host() {
            local HOST="$1"
            echo "========================================"
            echo "Cleaning $HOST..."
            echo "========================================"

            echo "Rebooting $HOST..."
            ssh "root@$HOST.penguin" "reboot"

            sleep 10

            wait_for_host "$HOST"

            echo "Running final cleanup on $HOST..."
            ssh "root@$HOST.penguin" "nix-collect-garbage -d && /run/current-system/bin/switch-to-configuration boot"

            echo "Done with $HOST."
        }

        WYSE_HOSTS=("wyse-DX" "wyse-CW" "wyse-91" "wyse-F8" "wyse-F4")

        if [ $# -eq 0 ]; then
            echo "Cleaning all wyse hosts..."
            for HOST in "''${WYSE_HOSTS[@]}"; do
                clean_host "$HOST"
            done
        elif [ $# -eq 1 ]; then
            HOST_TO_CLEAN="$1"
            if [[ ! "$HOST_TO_CLEAN" =~ ^wyse- ]]; then
                HOST_TO_CLEAN="wyse-$HOST_TO_CLEAN"
            fi
            if [[ " ''${WYSE_HOSTS[*]} " == *" $HOST_TO_CLEAN "* ]]; then
                clean_host "$HOST_TO_CLEAN"
            else
                echo "Error: Unknown host '$HOST_TO_CLEAN'"
                exit 1
            fi
        else
            echo "Usage: clean-wyse-hosts [host-name]"
            echo "Examples:"
            echo "  clean-wyse-hosts         # Clean all wyse hosts"
            echo "  clean-wyse-hosts wyse-F8 # Clean only wyse-F8"
            exit 1
        fi

        echo "All hosts cleaned."
      '';
    };
}
