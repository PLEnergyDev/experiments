#!/bin/bash

REMOTE_DIR="/home/dragos/RAPL/experiments"
ARCHIVE_NAME="archive.tar.gz"
FILES_OR_DIRS=("RAPLRust")

REMOTE_URL="$1"

for file_or_dir in "${FILES_OR_DIRS[@]}"; do
    if [[ ! -e "$file_or_dir" ]]; then
        echo "'$file_or_dir' does not exist."; exit 1;
    fi
done

tar --exclude="*results*" -czf "$ARCHIVE_NAME" "${FILES_OR_DIRS[@]}" || { echo "[ERROR] Failed to create archive"; exit 1; }
echo "[Ok] Created archive: $ARCHIVE_NAME"

scp "$ARCHIVE_NAME" $REMOTE_URL: || { echo "[ERROR] Failed to transfer archive"; exit 1; }
echo "[Ok] Transferred archive: $REMOTE_URL:$REMOTE_DIR"

ssh -t $REMOTE_URL "
    sudo bash -c '
        tar -xzf $ARCHIVE_NAME -C $REMOTE_DIR || { echo "[ERROR] Failed to extract files"; exit 1; }
        echo "[Ok] Extracted files"

        rm $ARCHIVE_NAME || { echo "[ERROR] Failed to cleanup"; exit 1; }
    '
"

rm "$ARCHIVE_NAME" || { echo "[ERROR] Failed to cleanup"; exit 1; }
echo "[Ok] Copying complete"

# convert sh to python script
#   - there should only be one script that traverses all dirs
#   - the script does the measuring, copying and structuring the data for every experiment in one go
#   - at the end of everything, does the average and plots
#   - if one experiments fail move to the next one
#
# assembly code analysis. Difference between IL and Assembly
#
# optinally get the JIT thing to work
#