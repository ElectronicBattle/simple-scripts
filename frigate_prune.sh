#!/bin/bash

DATASET_PATH="/mnt/mainraid/frigate_media/frigate/recordings"
QUOTA_LIMIT=80 # in GB
CURRENT_USAGE=$(du -sBG "$DATASET_PATH" | cut -f1 | sed 's/G//')

if [ "$CURRENT_USAGE" -ge "$QUOTA_LIMIT" ]; then
    # Find and delete the oldest files until the usage is below the limit
    while [ "$CURRENT_USAGE" -ge "$QUOTA_LIMIT" ]; do
        # Find the oldest file and delete it
        OLDEST_FILE=$(find "$DATASET_PATH" -type f -printf '%T+ %p\n' | sort | head -n 1 | cut -d' ' -f2-)
        if [ -n "$OLDEST_FILE" ]; then
            rm "$OLDEST_FILE"
            echo "Deleted: $OLDEST_FILE"
        fi
        CURRENT_USAGE=$(du -sBG "$DATASET_PATH" | cut -f1 | sed 's/G//')
    done
fi
