#!/bin/bash

# Set variables
WORKER_ID=***  # Your worker_id
CODE_ID=***  # Your code_id
KUZCO_PATH="/usr/local/bin/kuzco"    # Assume kuzco is in the user's root directory
LOG_FILE="$HOME/kuzco_monitor.log"
CPU_THRESHOLD=30            # CPU usage threshold
CHECK_INTERVAL=5            # Time interval to check CPU usage, in seconds

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if kuzco is running
is_kuzco_running() {
    pgrep -f "$KUZCO_PATH worker start --worker $WORKER_ID --code $CODE_ID" > /dev/null
}

# Function to start kuzco, capture and log output
start_kuzco() {
    if ! is_kuzco_running; then
        log "Attempting to start kuzco with worker ID: $WORKER_ID and code ID: $CODE_ID"
        
        # Start kuzco and capture output
        nohup "$KUZCO_PATH" worker start --worker $WORKER_ID --code $CODE_ID > "$HOME/kuzco_output.log" 2>&1 &
        
        # Wait a few seconds to check if the process started successfully
        sleep 2
        if is_kuzco_running; then
            log "Kuzco started successfully."
        else
            log "Failed to start kuzco. Command output:"
            cat "$HOME/kuzco_output.log" | tee -a "$LOG_FILE"
        fi
    else
        log "Kuzco is already running."
    fi
}

# Function to stop kuzco
stop_kuzco() {
    if is_kuzco_running; then
        log "Attempting to stop kuzco."
        pkill -f "$KUZCO_PATH worker start --worker $WORKER_ID --code $CODE_ID"

        # Wait a few seconds to ensure the process stops
        sleep 2
        if ! is_kuzco_running; then
            log "Kuzco stopped successfully."
        else
            log "Failed to stop kuzco."
        fi
    else
        log "Kuzco is not running."
    fi
}

# Function to get current CPU usage
get_cpu_usage() {
    top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//'
}

# Main loop to monitor CPU usage and control kuzco start/stop
while true; do
    cpu_usage=$(get_cpu_usage)

    log "Current CPU usage: ${cpu_usage}%"

    # Decide whether to start or stop kuzco based on CPU usage
    if (( $(echo "$cpu_usage < $CPU_THRESHOLD" | bc -l) )); then
        log "CPU usage below threshold. Attempting to start kuzco."
        start_kuzco
    else
        log "CPU usage above threshold. Stopping kuzco if running."
        stop_kuzco
    fi

    # Wait for the specified check interval
    sleep "$CHECK_INTERVAL"
done