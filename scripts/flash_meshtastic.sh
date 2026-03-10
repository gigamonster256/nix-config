#! /usr/bin/env nix-shell
#! nix-shell -i bash -p curl unzip jq

set -e

DRY_RUN=0
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=1
            shift
            ;;
        *)
            echo "Usage: $0 [-d|--dry-run]"
            exit 1
            ;;
    esac
done

MOUNT_POINT="/mnt/meshtastic"
DEVICE="/dev/sdb"
REPO="meshtastic/firmware"

mkdir -p "$MOUNT_POINT"
mount "$DEVICE" "$MOUNT_POINT" 2>/dev/null || sudo mount "$DEVICE" "$MOUNT_POINT"

BOARD_ID=$(grep -i "Board-ID:" "$MOUNT_POINT/INFO_UF2.TXT" | sed 's/.*Board-ID: *//' | tr -d '\r\n')
echo "Detected board ID: $BOARD_ID"

# mapping from Board ID on the device to the board name used in the firmware manifest
declare -A BOARD_MAP=(
    ["nRF52840-T1000-E-v1"]="tracker-t1000-e"
    ["HT-n5262"]="heltec-mesh-node-t114"
)

BOARD_NAME="${BOARD_MAP[$BOARD_ID]}"
if [ -z "$BOARD_NAME" ]; then
    echo "Unknown board ID: $BOARD_ID"
    umount "$MOUNT_POINT" 2>/dev/null || sudo umount "$MOUNT_POINT"
    exit 1
fi

echo "Mapped to board name: $BOARD_NAME"

ALPHA_TAG=$(curl -sL "https://api.github.com/repos/$REPO/releases" | jq -r '.[] | select(.prerelease == true) | .tag_name' | head -1)
echo "Latest alpha tag: $ALPHA_TAG"

MANIFEST_URL="https://github.com/$REPO/releases/download/$ALPHA_TAG/firmware-${ALPHA_TAG#v}.json"


PLATFORM=$(curl -sL "$MANIFEST_URL" | jq -r ".targets[] | select(.board == \"$BOARD_NAME\") | .platform")
if [ -z "$PLATFORM" ]; then
    echo "Could not find platform for board: $BOARD_NAME"
    umount "$MOUNT_POINT" 2>/dev/null || sudo umount "$MOUNT_POINT"
    exit 1
fi
echo "Detected platform: $PLATFORM"

FIRMWARE_ZIP="firmware-${PLATFORM}-${ALPHA_TAG#v}.zip"
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$ALPHA_TAG/$FIRMWARE_ZIP"

cd $(mktemp -d)

echo "Downloading $DOWNLOAD_URL..."
curl -sL "$DOWNLOAD_URL" -o firmware.zip

FIRMWARE_FILE=$(unzip -l firmware.zip 2>/dev/null | grep "firmware-${BOARD_NAME}-.*\.uf2$" | awk '{print $4}')
if [ -z "$FIRMWARE_FILE" ]; then
    echo "No firmware found for board: $BOARD_NAME"
    umount "$MOUNT_POINT" 2>/dev/null || sudo umount "$MOUNT_POINT"
    exit 1
fi

echo "Extracting $FIRMWARE_FILE..."
unzip -o firmware.zip "$FIRMWARE_FILE"

if [ $DRY_RUN -eq 1 ]; then
    echo "[DRY RUN] Would copy $FIRMWARE_FILE to $MOUNT_POINT/"
else
    cp "$FIRMWARE_FILE" "$MOUNT_POINT/" 2>/dev/null || sudo cp "$FIRMWARE_FILE" "$MOUNT_POINT/"
    echo "Firmware copied successfully!"
fi
echo "Unmounting $MOUNT_POINT..."
umount "$MOUNT_POINT" 2>/dev/null || sudo umount "$MOUNT_POINT"

echo "Done!"
