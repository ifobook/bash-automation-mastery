#!/usr/bin/env bash

set -euo pipefail

DISK_THRESHOLD="${1:-80}"
MEMORY_THRESHOLD="${2:-90}"

# Validate thresholds.
for value in "$DISK_THRESHOLD" "$MEMORY_THRESHOLD"; do
    if [[ ! "$value" =~ ^[0-9]+$ ]] || (( 10#$value > 100 )); then
        echo "ERROR: Thresholds must be between 0 and 100."
        exit 2
    fi
done

REPORT_DIR="./output/health"
mkdir -p "$REPORT_DIR"

REPORT_FILE="$REPORT_DIR/health_$(date +%Y%m%d_%H%M%S).txt"

# Read disk usage percentage.
DISK_USAGE=$(df -P / | awk 'NR==2 {gsub(/%/, "", $5); print $5}')

# Read memory statistics on macOS or Linux.
if [[ "$(uname)" == "Darwin" ]]; then
    MEMORY_USAGE=$(vm_stat | awk '
        /Pages free:/ {free=$3}
        /Pages active:/ {active=$3}
        /Pages inactive:/ {inactive=$3}
        /Pages speculative:/ {speculative=$3}
        /Pages wired down:/ {wired=$4}
        /Pages occupied by compressor:/ {compressed=$5}
        END {
            total=free+active+inactive+speculative+wired+compressed
            if (total > 0)
                printf "%.0f", ((active+wired+compressed)/total)*100
            else
                print 0
        }
    ')
else
    MEMORY_USAGE=$(free | awk '/Mem:/ {printf "%.0f", ($2-$7)/$2*100}')
fi

PROCESS_COUNT=$(ps -e | wc -l | tr -d ' ')

STATUS=0

{
    echo "================================="
    echo "SYSTEM HEALTH REPORT"
    echo "================================="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo "Operating System: $(uname -s)"
    echo "Disk Usage: ${DISK_USAGE}%"
    echo "Memory Usage: ${MEMORY_USAGE}%"
    echo "Running Processes: $PROCESS_COUNT"
    echo

    if (( DISK_USAGE >= DISK_THRESHOLD )); then
        echo "WARNING: Disk usage exceeds threshold!"
        STATUS=1
    else
        echo "PASS: Disk usage is healthy."
    fi

    if (( MEMORY_USAGE >= MEMORY_THRESHOLD )); then
        echo "WARNING: Memory usage exceeds threshold!"
        STATUS=1
    else
        echo "PASS: Memory usage is healthy."
    fi

    echo "================================="
} | tee "$REPORT_FILE"

# Determine the final exit status from the report.
if grep -q "WARNING:" "$REPORT_FILE"; then
    STATUS=1
fi

echo "Report saved to: $REPORT_FILE"
exit "$STATUS"
