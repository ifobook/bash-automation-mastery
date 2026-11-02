#!/usr/bin/env bash

# Reusable logging function.
log_message() {
    local level="$1"
    local message="$2"
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$message"
}

# Validate a directory name.
validate_name() {
    local name="$1"

    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_message "ERROR" "Invalid name: $name"
        return 2
    fi
}

# Create a directory safely.
create_directory() {
    local directory="$1"

    mkdir -p "$directory"
    log_message "INFO" "Directory ready: $directory"
}

# Count files inside a directory.
count_files() {
    local directory="$1"
    local count

    count=$(find "$directory" -type f | wc -l | tr -d ' ')
    printf '%s\n' "$count"
}
