#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load reusable functions.
source "$PROJECT_ROOT/lib/common.sh"

WORKSPACE_NAME="${1:-}"
WORKSPACE_ROOT="$PROJECT_ROOT/output/workspaces"
TEMP_FILE=""

cleanup() {
    if [[ -n "$TEMP_FILE" && -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
}

on_interrupt() {
    log_message "WARNING" "Script interrupted. Cleaning up."
    exit 130
}

trap cleanup EXIT
trap on_interrupt INT TERM

# Validate required input.
if [[ -z "$WORKSPACE_NAME" ]]; then
    log_message "ERROR" "Usage: $0 <workspace-name>"
    exit 2
fi

validate_name "$WORKSPACE_NAME"

create_directory "$WORKSPACE_ROOT/$WORKSPACE_NAME"

TEMP_FILE="$(mktemp)"

printf 'Workspace: %s\nCreated: %s\n' \
    "$WORKSPACE_NAME" "$(date)" > "$TEMP_FILE"

# Preserve existing metadata on repeated runs.
METADATA="$WORKSPACE_ROOT/$WORKSPACE_NAME/metadata.txt"

if [[ ! -e "$METADATA" ]]; then
    cp "$TEMP_FILE" "$METADATA"
    log_message "INFO" "Metadata created."
else
    log_message "INFO" "Metadata already exists; preserving it."
fi

FILE_COUNT="$(count_files "$WORKSPACE_ROOT/$WORKSPACE_NAME")"

log_message "INFO" "Total files: $FILE_COUNT"
log_message "SUCCESS" "Automation completed."
