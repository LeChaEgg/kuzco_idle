#!/bin/bash

# Set variables
NAME="007"  # Worker name to manage

# Worker configuration function
get_worker_config() {
    local worker_name=$1
    case "$worker_name" in
        "000") echo "zXJvdna3v28u0ORGvuWA1 0ac4124f-91b9-4d4f-ae82-503cfdb7e430" ;;
        "001") echo "ZdSPjm5zjozFdLuwC_dX2 32c47b6f-0301-48ff-a625-a743e7686e6e" ;;
        "002") echo "i7Ab7SCrn0vhtXqReGMh8 71a0818a-acc4-49ec-a400-7e473274af36" ;;
        "003") echo "9pw-AMCfId53Lt8mMoJHw 475bab41-edd5-4e2e-b1df-fa7117a02a2d" ;;
        "004") echo "cdLweM8BC5efI8tR1hbgz 7813aa64-d5ce-4f16-980e-47531a1114c3" ;;
        "005") echo "ymNYMz5A38vGXzY5pSkIP ddf84d1a-3e90-4f20-b882-63bbb4e00d43" ;;
        "006") echo "s33ptmCpcfS0LvQ6FuM3r e32b86b8-7fbc-4833-bb61-27d03f4ea0f4" ;;
        "007") echo "xyILh90zvdIqenjn1Bn7o 1fde51ba-1f91-4a4a-acfc-5466a2750841" ;;
        "008") echo "zsoytjhvJ7nuGLFeGns6a 85286ac1-5664-406c-b94a-0a9d48919607" ;;
        "009") echo "wv6edV1_v95LHFZL3MbwB f05e729d-ebb8-4251-8400-85831ad1a892" ;;
        "010") echo "YuQBmgc5jfZ-6oQBR0n3N 450e4c41-cb3f-4cbb-91ca-56f71936ebfd" ;;
        "011") echo "3DZl6DJAo1junf3y4y0Jq 8814e3ec-2be4-4c54-a64b-48764a52e112" ;;
        "100") echo "YFheRTJp5-ahc044wbhUO b46c498a-8bd0-43ce-aef2-46ea97c76f13" ;;
        "yahaha") echo "8nhLhvNSuHPIOGa2ABFp3 6087adf8-955e-4ac8-a61f-219a361194c6" ;;
        "SSY") echo "7zW6NHBTHazyH3pRay9cW 61916205-0b38-4d17-ade6-7dc62a745820" ;;
        "M4Pro") echo "4hrSxj5X1HG5jvbSl_B12 3ef113c2-aad4-4601-b593-6e42d7c4b206" ;;
        "M000") echo "s8tPIaWZkL_v4nYATn4fA 64ced172-43f8-4247-bac3-5ae983af79eb" ;;
        "M001") echo "9V27-kL4CKR6eJGt7dvc2 411eb352-c4f1-40e2-9185-e8f14260467d" ;;
        "M002") echo "J1-fQr7A5bVQIV0n085qi 65ed503b-9a7d-46b1-b0c8-e1ee3439df44" ;;
        "M003") echo "nIVe0XoDvcYhOsL_jD5gs 5756d86b-a04a-445d-8f47-00ba987a25d1" ;;
        "M004") echo "YqBqDVUhzqH4WNynLia8P 7bb9e5d5-e256-4a4b-91ad-42c5c13d7b7c" ;;
        "M005") echo "CJ01JhKM7V_P4jFb4ZpdW 3a2fd691-3a42-4f11-bd6f-6d04511cb4f3" ;;
        "M006") echo "rYO9BYVQw6mmwpXgfHdBf a2989efd-0145-48b0-ac74-d67fcc478a2a" ;;
        "M007") echo "7xK-QaB4bluIm-0Bt4tRI d14f2ea2-4955-4a36-829b-d16d14eafebc" ;;
        "M008") echo "Wy0YXNG8W12R6eO-DxbJS b5b741be-36f1-4b5f-82e2-ed17a98e1656" ;;
        "M009") echo "Sf5oOjMEsQM5dSo7HBq9c 9c63a1d1-52f5-4a82-9a5f-1393ab470a4f" ;;
        "M010") echo "XmmEEyJ3tmB1wLzIrdN71 eef7dca6-0ceb-4662-a52c-5451b9b95a7a" ;;
        "M011") echo "Zpl68IxEe3gBZvSe-SVXy 70954a57-53c8-4b85-9289-855728993a3c" ;;
        "Mzxw") echo "rW_DPaGsOpGSWyCXc30R0 07368c7f-ad0f-4546-9f6e-44ee8a497d59" ;;
        "Mxie") echo "HmmxFNh2Z-TbQ_Zwvv49y e045b539-c20d-4bc5-aef2-47b7682bcad6" ;;
        *) echo "" ;;
    esac
}

# Basic configuration
KUZCO_PATH="/usr/local/bin/kuzco"
LOG_FILE="$HOME/kuzco_monitor.log"
OUTPUT_LOG="$HOME/kuzco_output_monitor.log"
CPU_THRESHOLD=30
CHECK_INTERVAL=3  # Change the check interval from 5 seconds to 3 seconds
GPU_POWER_THRESHOLD=1  # GPU power threshold (watts), corresponding to 1W
DEBUG_MODE=true

# Monitoring variables
LAST_INFERENCE_TIME=$(date +%s)
HOURLY_INFERENCE_COUNT=0
LAST_HOUR_REPORT=$(date +%s)
LAST_GPU_HIGH_LOAD=0  # Add GPU high load time record
CONTINUOUS_HIGH_LOAD_THRESHOLD=30  # Continuous high load threshold (seconds)

# Read worker configuration from the built-in database
load_worker_config() {
    local config=$(get_worker_config "$NAME")
    if [ -z "$config" ]; then
        echo "Error: Worker with name '$NAME' not found in database!"
        exit 1
    fi
    WORKER_ID=$(echo "$config" | awk '{print $1}')
    CODE_ID=$(echo "$config" | awk '{print $2}')
    echo "Loaded config for worker '$NAME': WORKER_ID=$WORKER_ID, CODE_ID=$CODE_ID"
}

# Unified log processing function
log() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$message"
    [ "$DEBUG_MODE" = true ] && echo "$message" >> "$LOG_FILE"
}

# Unified process check function
check_process() {
    local process_name=$1
    local process_pattern=$2
    pgrep -f "$process_pattern" > /dev/null
}

# Process management function
manage_process() {
    local action=$1
    local process_name=$2
    local process_pattern=$3
    local start_cmd=$4

    case "$action" in
        "start")
            if ! check_process "$process_name" "$process_pattern"; then
                log "Starting $process_name..."
                eval "$start_cmd"
                sleep 2
                check_process "$process_name" "$process_pattern" && \
                    log "$process_name started successfully." || \
                    log "Failed to start $process_name."
            else
                log "$process_name is already running."
            fi
            ;;
        "stop")
            if check_process "$process_name" "$process_pattern"; then
                log "Stopping $process_name..."
                pkill -f "$process_pattern"
                sleep 2
                ! check_process "$process_name" "$process_pattern" && \
                    log "$process_name stopped successfully." || \
                    log "Failed to stop $process_name."
            else
                log "$process_name is not running."
            fi
            ;;
    esac
}

# Clean old logs
clean_old_logs() {
    local two_days_ago=$(date -v-2d +%s)
    local log_files= তন্মokuoikuzco_output.log")
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            local log_time=$(stat -f %m "$log_file")
            if [ $log_time -lt $two_days_ago ]; then
                log "Cleaning old log file: $log_file"
                : > "$log_file"
            fi
        fi
    done
}

# Get GPU power (unit: watts)
get_gpu_power() {
    # Check for sudo permissions
    if [ "$(id -u)" != "0" ]; then
        log "Warning: sudo permission is required to get GPU power"
        return 0
    fi

    # Directly use sudo powermetrics to get GPU power
    local gpu_power_raw=$(sudo powermetrics --samplers gpu_power -n 1 2>/dev/null)
    if [ $? -ne 0 ]; then
        log "Warning: powermetrics command failed, please make sure you have sudo permission"
        echo "0"
        return
    fi

    # Use a more precise regular expression to extract GPU power data
    local gpu_power_mw=$(echo "$gpu_power_raw" | grep -oE 'GPU Power: [0-9]+([.][0-9]+)? mW' | head -n 1 | grep -oE '[0-9]+([.][0-9]+)?')
    
    # Verify that the extracted data is not empty
    if [ -z "$gpu_power_mw" ]; then
        log "Warning: Unable to extract GPU power data from powermetrics output"
        echo "0"
        return
    fi

    # Validate and convert power data
    if [[ $gpu_power_mw =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        local gpu_power=$(echo "scale=3; $gpu_power_mw / 1000" | bc)
        if [ -z "$gpu_power" ]; then
            log "Warning: GPU power data conversion failed"
            echo "0"
        else
            echo "$gpu_power"
        fi
    else
        log "Warning: Invalid format of extracted GPU power data: $gpu_power_mw"
        echo "0"
    fi
}

# Monitor kuzco output
monitor_kuzco_output() {
    local current_time=$(date +%s)
    
    # Generate hourly report
    if [ $((current_time - LAST_HOUR_REPORT)) -ge 3600 ]; then
        log "Hourly Report: $HOURLY_INFERENCE_COUNT inferences in the last hour"
        HOURLY_INFERENCE_COUNT=0
        LAST_HOUR_REPORT=$current_time
    fi

    # Check GPU power
    local gpu_power=$(get_gpu_power)
    log "Current GPU power: ${gpu_power}W"

    # Detect inference based on GPU power
    if (( $(echo "$gpu_power >= $GPU_POWER_THRESHOLD" | bc -l) )); then
        if [ $LAST_GPU_HIGH_LOAD -eq 0 ]; then
            LAST_GPU_HIGH_LOAD=$current_time
        elif [ $((current_time - LAST_GPU_HIGH_LOAD)) -ge $CONTINUOUS_HIGH_LOAD_THRESHOLD ]; then
            # GPU continuous high load exceeds the threshold, record one inference
            HOURLY_INFERENCE_COUNT=$((HOURLY_INFERENCE_COUNT + 1))
            LAST_INFERENCE_TIME=$current_time
            log "Continuous high GPU load detected for ${CONTINUOUS_HIGH_LOAD_THRESHOLD}s. Total in current hour: $HOURLY_INFERENCE_COUNT"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - New inference detected by continuous GPU usage. Total in current hour: $HOURLY_INFERENCE_COUNT" >> "$OUTPUT_LOG"
            LAST_GPU_HIGH_LOAD=$current_time  # Reset the timer to avoid repeated counting
        fi
    else
        if [ $LAST_GPU_HIGH_LOAD -ne 0 ]; then
            # GPU load changes from high to low, record one inference
            HOURLY_INFERENCE_COUNT=$((HOURLY_INFERENCE_COUNT + 1))
            LAST_INFERENCE_TIME=$current_time
            log "Inference detected by GPU usage. Total in current hour: $HOURLY_INFERENCE_COUNT"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - New inference detected by GPU usage. Total in current hour: $HOURLY_INFERENCE_COUNT" >> "$OUTPUT_LOG"
            LAST_GPU_HIGH_LOAD=0
        fi
    fi

    # Check if a restart is needed
    if [ $((current_time - LAST_INFERENCE_TIME)) -ge 3600 ]; then
        log "No inference detected for over an hour. Restarting kuzco..."
        manage_process "stop" "kuzco" "$KUZCO_PATH worker start --worker $WORKER_ID --code $CODE_ID"
        sleep 5
        manage_process "start" "kuzco" "$KUZCO_PATH worker start --worker $WORKER_ID --code $CODE_ID" \
            "nohup \"$KUZCO_PATH\" worker start --worker $WORKER_ID --code $CODE_ID > \"$HOME/kuzco_output.log\" 2>&1 &"
        LAST_INFERENCE_TIME=$current_time
    fi

    # Check inference output
    if [ "$DEBUG_MODE" = true ] && [ -f "$HOME/kuzco_output.log" ]; then
        # Get the number of new inference completions
        new_inferences=$(grep -c "1 Inference finished from subscription" "$HOME/kuzco_output.log")
        if [ $new_inferences -gt 0 ]; then
            HOURLY_INFERENCE_COUNT=$((HOURLY_INFERENCE_COUNT + new_inferences))
            LAST_INFERENCE_TIME=$current_time
            log "Inference finished. Total in current hour: $HOURLY_INFERENCE_COUNT"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - $new_inferences new inference(s) detected. Total in current hour: $HOURLY_INFERENCE_COUNT" >> "$OUTPUT_LOG"
            # Clear the log file to avoid repeated counting
            : > "$HOME/kuzco_output.log"
        fi
    fi
}

# Initialization
load_worker_config

# Main loop
while true; do
    cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    log "Current CPU usage: ${cpu_usage}%"

    if (( $(echo "$cpu_usage < $CPU_THRESHOLD" | bc -l) )); then
        log "CPU usage below threshold. Attempting to start kuzco."
        manage_process "start" "kuzco" "$KUZCO_PATH worker start --worker $WORKER_ID --code $CODE_ID" \
            "nohup \"$KUZCO_PATH\" worker start --worker $WORKER_ID --code $CODE_ID > \"$HOME/kuzco_output.log\" 2>&1 &"
    else
        log "CPU usage above threshold. Stopping kuzco if running."
        manage_process "stop" "kuzco" "$KUZCO_PATH worker start --worker $WORKER_ID --code $CODE_ID"
    fi

    monitor_kuzco_output
    clean_old_logs
    sleep "$CHECK_INTERVAL"
done