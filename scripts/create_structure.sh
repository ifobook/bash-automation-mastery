#!/usr/bin/env bash

set -euo pipefail

# Accept an optional destination directory.
TARGET_DIR="${1:-./output/project}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Validate the destination.
if [[ -z "$TARGET_DIR" || "$TARGET_DIR" == "/" ]]; then
    echo "ERROR: Invalid destination directory."
    exit 1
fi

echo "Starting directory automation..."

# Create directories safely, even if they already exist.
mkdir -p "$TARGET_DIR"/{config,logs,data,backups}

# Create files without overwriting existing content.
for file in config/app.conf logs/application.log data/records.txt; do
    if [[ ! -e "$TARGET_DIR/$file" ]]; then
        touch "$TARGET_DIR/$file"
        echo "Created: $file"
    else
        echo "Already exists: $file"
    fi
done

# Add default configuration only once.
if [[ ! -s "$TARGET_DIR/config/app.conf" ]]; then
    echo "APP_NAME=BashAutomationMastery" > "$TARGET_DIR/config/app.conf"
    echo "ENVIRONMENT=development" >> "$TARGET_DIR/config/app.conf"
fi

# Generate a timestamped backup filename.
BACKUP_FILE="$TARGET_DIR/backups/backup_${TIMESTAMP}.txt"

if [[ ! -e "$BACKUP_FILE" ]]; then
    echo "Backup created at: $(date)" > "$BACKUP_FILE"
fi

echo "Directory automation completed successfully."
