#!/bin/bash

REMOTE_DIR="/home/dragos/RAPL/experiments"
ARCHIVE_NAME="archive.tar.gz"

# Check if both arguments (REMOTE_URL and SOURCE_DIR) are provided
if [[ $# -ne 2 ]]; then
    echo "Usage: $(basename $0) <REMOTE_URL> <SOURCE_DIR>"
    exit 1
fi

REMOTE_URL="$1"
SOURCE_DIR="$2"

# Check if the specified directory exists
if [[ ! -e "$SOURCE_DIR" ]]; then
    echo "[ERROR] '$SOURCE_DIR' does not exist."
    exit 1
fi

# Create the archive
tar --exclude="*results*" --exclude="expected" -czf "$ARCHIVE_NAME" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" || {
    echo "[ERROR] Failed to create archive";
    exit 1;
}
echo "[Ok] Created archive: $ARCHIVE_NAME"

# Transfer the archive
scp "$ARCHIVE_NAME" $REMOTE_URL: || {
    echo "[ERROR] Failed to transfer archive";
    exit 1;
}
echo "[Ok] Transferred archive: $REMOTE_URL:$REMOTE_DIR"

# Extract the archive on the remote server
ssh -t $REMOTE_URL "
    bash -c '
        tar -xzf $ARCHIVE_NAME -C $REMOTE_DIR || { echo \"[ERROR] Failed to extract files\"; exit 1; }
        echo \"[Ok] Extracted files\"

        rm $ARCHIVE_NAME || { echo \"[ERROR] Failed to cleanup\"; exit 1; }
    '
"

# Cleanup the local archive
rm "$ARCHIVE_NAME" || { echo "[ERROR] Failed to cleanup"; exit 1; }
echo "[Ok] Copying complete"
