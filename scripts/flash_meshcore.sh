#! /usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq

set -e

DRY_RUN=0
TYPE="companion"
VARIANT="ble"
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=1
            shift
            ;;
        -t|--type)
            TYPE="$2"
            shift 2
            ;;
        -v|--variant)
            VARIANT="$2"
            shift 2
            ;;
        *)
            echo "Usage: $0 [-d|--dry-run] [-t|--type companion|repeater|room-server] [-v|--variant ble|usb]"
            exit 1
            ;;
    esac
done

MOUNT_POINT="/mnt/meshcore"
DEVICE="/dev/sda"
REPO="meshcore-dev/MeshCore"

mount --mkdir "$DEVICE" "$MOUNT_POINT" 2>/dev/null || sudo mount --mkdir "$DEVICE" "$MOUNT_POINT"

BOARD_ID=$(grep -i "Board-ID:" "$MOUNT_POINT/INFO_UF2.TXT" | sed 's/.*Board-ID: *//' | tr -d '\r\n')
echo "Detected board ID: $BOARD_ID"

# mapping from Board ID on the device to the board name used in MeshCore release assets
declare -A BOARD_MAP=(
    ["nRF52840-T1000-E-v1"]="t1000e"
    ["HT-n5262"]="Heltec_t114"
)

BOARD_NAME="${BOARD_MAP[$BOARD_ID]}"
if [ -z "$BOARD_NAME" ]; then
    echo "Unknown board ID: $BOARD_ID"
    umount "$MOUNT_POINT" 2>/dev/null || sudo umount "$MOUNT_POINT"
    exit 1
fi

echo "Mapped to board name: $BOARD_NAME"

# MeshCore publishes one release per firmware type (e.g. companion-v1.17.1, repeater-v1.17.1).
# asset infix differs per type (and variant for companion)
case $TYPE in
    companion)
        ASSET_INFIX="companion_radio_${VARIANT}"
        ;;
    repeater)
        ASSET_INFIX="repeater"
        ;;
    room-server)
        ASSET_INFIX="room_server"
        ;;
    *)
        echo "Unknown type: $TYPE (expected companion, repeater, or room-server)"
        umount "$MOUNT_POINT" 2>/dev/null || sudo umount "$MOUNT_POINT"
        exit 1
        ;;
esac

# Pick the latest release of the wanted type by published date (releases are returned newest first,
# but sort anyway). Paginate in case the newest matching release falls beyond the first page.
RELEASE_TAG=""
for PAGE in 1 2 3; do
    RELEASES=$(curl -sL "https://api.github.com/repos/$REPO/releases?per_page=100&page=$PAGE")
    RELEASE_TAG=$(echo "$RELEASES" | jq -r --arg prefix "$TYPE-" '
      [ .[] | select(.draft | not)
             | select(.tag_name | startswith($prefix))
      ] | sort_by(.published_at) | last | .tag_name
    ')
    if [ -n "$RELEASE_TAG" ] && [ "$RELEASE_TAG" != "null" ]; then
        break
    fi
done

if [ -z "$RELEASE_TAG" ] || [ "$RELEASE_TAG" = "null" ]; then
    echo "Could not find a $TYPE release"
    umount "$MOUNT_POINT" 2>/dev/null || sudo umount "$MOUNT_POINT"
    exit 1
fi

echo "Latest $TYPE tag: $RELEASE_TAG"

# Match the asset by board prefix rather than exact name; asset names embed a short commit hash
ASSET_NAME=$(curl -sL "https://api.github.com/repos/$REPO/releases/tags/$RELEASE_TAG" | jq -r --arg prefix "${BOARD_NAME}_${ASSET_INFIX}-" '
  [.assets[] | select(.name | test("^" + $prefix + ".*\\.uf2$"))] | first | .name
')

if [ -z "$ASSET_NAME" ] || [ "$ASSET_NAME" = "null" ]; then
    echo "No firmware found for board: $BOARD_NAME (infix: $ASSET_INFIX)"
    umount "$MOUNT_POINT" 2>/dev/null || sudo umount "$MOUNT_POINT"
    exit 1
fi

DOWNLOAD_URL="https://github.com/$REPO/releases/download/$RELEASE_TAG/$ASSET_NAME"

cd $(mktemp -d)

echo "Downloading $DOWNLOAD_URL..."
curl -sL "$DOWNLOAD_URL" -o "$ASSET_NAME"

if [ $DRY_RUN -eq 1 ]; then
    echo "[DRY RUN] Would copy $ASSET_NAME to $MOUNT_POINT/"
else
    cp "$ASSET_NAME" "$MOUNT_POINT/" 2>/dev/null || sudo cp "$ASSET_NAME" "$MOUNT_POINT/"
    echo "Firmware copied successfully!"
fi

echo "Unmounting $MOUNT_POINT..."
sync
umount "$MOUNT_POINT" 2>/dev/null || sudo umount "$MOUNT_POINT"

echo "Done!"
