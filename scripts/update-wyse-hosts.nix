{
  packages.update-wyse-hosts =
    {
      writeShellApplication,
      nixos-rebuild,
    }:
    writeShellApplication {
      name = "update-wyse-hosts";
      runtimeInputs = [
        nixos-rebuild
      ];
      text = ''
        usage() {
            echo "Usage: update-wyse-hosts [host-name]"
            echo "Examples:"
            echo "  update-wyse-hosts           # Update all wyse hosts"
            echo "  update-wyse-hosts wyse-F8   # Update only wyse-F8"
        }

        deploy_host() {
            local HOST_NAME="$1"
            echo "Updating $HOST_NAME..."
            nixos-rebuild switch \
              --no-reexec \
              --target-host "root@$HOST_NAME.penguin" \
              --flake ".#$HOST_NAME"
            echo "$HOST_NAME updated successfully!"
        }

        # Define all wyse hosts
        WYSE_HOSTS=("wyse-DX" "wyse-CW" "wyse-91" "wyse-F8" "wyse-F4")

        # check for -h or --help
        for arg in "$@"; do
            if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
                usage
                exit 0
            fi
        done

        # update all 
        if [ $# -eq 0 ]; then
            echo "Updating all wyse hosts..."
            for HOST in "''${WYSE_HOSTS[@]}"; do
                deploy_host "$HOST"
            done
        # update specific host
        elif [ $# -eq 1 ]; then
            HOST_TO_UPDATE="$1"
            
            # Allow shorthand like "F8" to become "wyse-F8"
            if [[ ! "$HOST_TO_UPDATE" =~ ^wyse- ]]; then
                HOST_TO_UPDATE="wyse-$HOST_TO_UPDATE"
            fi
            
            if [[ " ''${WYSE_HOSTS[*]} " == *" $HOST_TO_UPDATE "* ]]; then
                deploy_host "$HOST_TO_UPDATE"
            else
                echo "Error: Unknown host '$HOST_TO_UPDATE'."
                usage
                exit 1
            fi
        else
            echo "Error: Invalid number of arguments."
            usage
            exit 1
        fi

        echo "All updates completed."
      '';
    };
}
