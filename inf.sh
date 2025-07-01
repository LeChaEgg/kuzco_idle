#!/bin/bash
# ==============================================================================
# inference.net Node Hosting Management Script (v13 - Smart Evasion Final)
#
# -- Core Logic --
# 1. Smart Evasion: When CPU load is high, stop inference only when the GPU also starts working (resource conflict),
#    avoiding unnecessary restarts and maximizing effective working time.
# 2. Battery Protection: Monitors real physical battery level, locks below 15%, unlocks above 70%, suitable for insufficient power supply scenarios.
# 3. Idle Restart: Restarts dead/idle processes that have no inference tasks for more than 1 hour by monitoring GPU power consumption.
# 4. Process Cleanup: Each stop is forcefully cleaned up with `sudo pkill` to prevent zombie processes.
# 5. Environment Compatibility: Uses `screen` to create a virtual terminal for the program, solving the bug of the official Launcher in the background.
#
# -- Usage --
# 1. chmod +x inf.sh
# 2. ./inf.sh <WorkerName> (do not add sudo)
# 3. (Remote Management) tmux new -s inference; ./inf.sh <WorkerName>; Ctrl+b, d
# ==============================================================================

# --- 基础配置 ---
if [ -z "$1" ]; then
    echo "错误: 请提供Worker名称作为脚本的第一个参数。"
    echo "用法: $0 <Worker名称>"
    exit 1
fi
NAME="$1"

INFERENCE_PATH=$(command -v inference)
if [ -z "$INFERENCE_PATH" ]; then
    echo "错误: 在你的 PATH 中未找到 'inference' 命令。请确保已正确安装。"
    exit 1
fi

LOG_FILE="$HOME/inference_monitor.log"
# In screen mode, the program output is within the screen session, this file may be empty, but it is kept just in case
OUTPUT_LOG="$HOME/inference_output.log" 

# --- Threshold Configuration ---
CPU_THRESHOLD=50      # Above this value, it is considered that a high-priority task is running
CHECK_INTERVAL=15     # Loop check interval (seconds)
GPU_POWER_THRESHOLD=1 # Above this value (watts), the GPU is considered to be working
IDLE_RESTART_TIME=3600 # Restart if the GPU is idle for more than this time (seconds)
BATTERY_LOW_THRESHOLD=15  # Lock below this battery percentage
BATTERY_HIGH_THRESHOLD=70 # Unlock above this battery percentage

# --- Internal State Variables ---
LAST_INFERENCE_TIME=$(date +%s)
INFERENCE_LOCKED_BY_BATTERY=false

# --- Function Definitions ---
get_worker_config() {
    local worker_name=$1
    case "$worker_name" in
        "000") echo "0ac4124f-91b9-4d4f-ae82-503cfdb7e430" ;;
        "001") echo "32c47b6f-0301-48ff-a625-a743e7686e6e" ;;
        "002") echo "71a0818a-acc4-49ec-a400-7e473274af36" ;;
        "003") echo "475bab41-edd5-4e2e-b1df-fa7117a02a2d" ;;
        "004") echo "7813aa64-d5ce-4f16-980e-47531a1114c3" ;;
        "005") echo "ddf84d1a-3e90-4f20-b882-63bbb4e00d43" ;;
        "006") echo "e32b86b8-7fbc-4833-bb61-27d03f4ea0f4" ;;
        "007") echo "1fde51ba-1f91-4a4a-acfc-5466a2750841" ;;
        "008") echo "85286ac1-5664-406c-b94a-0a9d48919607" ;;
        "009") echo "f05e729d-ebb8-4251-8400-85831ad1a892" ;;
        "010") echo "450e4c41-cb3f-4cbb-91ca-56f71936ebfd" ;;
        "011") echo "8814e3ec-2be4-4c54-a64b-48764a52e112" ;;
        "100") echo "b46c498a-8bd0-43ce-aef2-46ea97c76f13" ;;
        "yahaha") echo "6087adf8-955e-4ac8-a61f-219a361194c6" ;;
        "SSY") echo "61916205-0b38-4d17-ade6-7dc62a745820" ;;
        "M4Pro") echo "3ef113c2-aad4-4601-b593-6e42d7c4b206" ;;
        "M000") echo "64ced172-43f8-4247-bac3-5ae983af79eb" ;;
        "M001") echo "411eb352-c4f1-40e2-9185-e8f14260467d" ;;
        "M002") echo "65ed503b-9a7d-46b1-b0c8-e1ee3439df44" ;;
        "M003") echo "5756d86b-a04a-445d-8f47-00ba987a25d1" ;;
        "M004") echo "7bb9e5d5-e256-4a4b-91ad-42c5c13d7b7c" ;;
        "M005") echo "3a2fd691-3a42-4f11-bd6f-6d04511cb4f3" ;;
        "M006") echo "a2989efd-0145-48b0-ac74-d67fcc478a2a" ;;
        "M007") echo "d14f2ea2-4955-4a36-829b-d16d14eafebc" ;;
        "M008") echo "b5b741be-36f1-4b5f-82e2-ed17a98e1656" ;;
        "M009") echo "9c63a1d1-52f5-4a82-9a5f-1393ab470a4f" ;;
        "M010") echo "eef7dca6-0ceb-4662-a52c-5451b9b95a7a" ;;
        "M011") echo "70954a57-53c8-4b85-9289-855728993a3c" ;;
        "Mzxw") echo "07368c7f-ad0f-4546-9f6e-44ee8a497d59" ;;
        "Mxie") echo "e045b539-c20d-4bc5-aef2-47b7682bcad6" ;;
        *) echo "" ;;
    esac
}

log() { local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"; echo "$message" >> "$LOG_FILE"; echo "$message"; }
check_process() { pgrep -f "$1" > /dev/null; }

get_battery_level() {
    if ! command -v pmset &> /dev/null; then echo 100; return; fi
    local battery_percentage
    battery_percentage=$(pmset -g batt | grep -o '[0-9]*%' | sed 's/%//')
    if [ -z "$battery_percentage" ]; then echo 100; else echo "$battery_percentage"; fi
}

manage_process() {
    local action=$1; local process_pattern=$2; local start_cmd=$3
    case "$action" in
        "start")
            if ! check_process "$process_pattern"; then
                log "Starting inference node using screen..."; eval "$start_cmd"
                sleep 5 
                if check_process "$process_pattern"; then
                    log "inference node started successfully."; LAST_INFERENCE_TIME=$(date +%s)
                else
                    log "Error: inference node failed to start."; fi
            fi ;;
        "stop")
            if check_process "$process_pattern"; then 
                log "Performing cleanup: Force stopping all inference related processes...";
                sudo pkill -f "SCREEN" > /dev/null 2>&1; sudo pkill -f "inference" > /dev/null 2>&1; sudo pkill -f "ollama" > /dev/null 2>&1
                sleep 2
                if ! check_process "$process_pattern"; then log "Cleanup complete."; else log "Warning: Target process still exists after cleanup."; fi
            fi ;;
    esac
}

get_gpu_power() {
    local gpu_power_raw; gpu_power_raw=$(sudo powermetrics --samplers gpu_power -n 1 2>/dev/null)
    if [ $? -ne 0 ]; then
        if ! sudo -n true 2>/dev/null; then log "Warning: sudo permission check failed. Please configure passwordless sudo for powermetrics and pkill."; else log "Warning: powermetrics command failed."; fi
        echo "0"; return
    fi
    local gpu_power_mw; gpu_power_mw=$(echo "$gpu_power_raw" | grep "GPU Power" | awk '{print $3}')
    if [[ "$gpu_power_mw" =~ ^[0-9]+([.][0-9]+)?$ ]]; then echo "$(awk "BEGIN {print $gpu_power_mw / 1000}")"; else echo "0"; fi
}

monitor_inference_process() {
    local current_time=$(date +%s); local gpu_power=$(get_gpu_power); log "Current GPU power: ${gpu_power}W"
    if (( $(echo "$gpu_power >= $GPU_POWER_THRESHOLD" | bc -l) )); then
        LAST_INFERENCE_TIME=$current_time; log "GPU under load, resetting idle timer."
    fi
    local time_since_last_activity=$((current_time - LAST_INFERENCE_TIME))
    if [ "$time_since_last_activity" -ge "$IDLE_RESTART_TIME" ]; then
        log "Node has been idle for more than $(($IDLE_RESTART_TIME / 60)) minutes, restarting..."; manage_process "stop" "$PROCESS_PATTERN"; sleep 5; manage_process "start" "$PROCESS_PATTERN" "$START_COMMAND"
    else
        log "Time since last GPU activity: ${time_since_last_activity}s / ${IDLE_RESTART_TIME}s";
    fi
}

# --- Main Program ---
echo "--- inference.net Node Management Script (v13) Started ---"
: > "$LOG_FILE"
log "Script started, Worker name: $NAME"
log "Running as user $(whoami)"

config=$(get_worker_config "$NAME")
if [ -z "$config" ]; then log "Error: Worker with name '$NAME' not found in the database!"; exit 1; fi
CODE_ID=$config
log "Configuration loaded successfully, CODE_ID: $CODE_ID"

PROCESS_PATTERN="$INFERENCE_PATH node start --code $CODE_ID"
START_COMMAND="screen -d -m \"$INFERENCE_PATH\" node start --code \"$CODE_ID\""

# --- Main Loop ---
while true; do
    # 1. Battery Management Logic (Highest Priority)
    battery_level=$(get_battery_level)
    log "Current battery: ${battery_level}%"

    if [ "$battery_level" -lt "$BATTERY_LOW_THRESHOLD" ]; then
        INFERENCE_LOCKED_BY_BATTERY=true
    elif [ "$battery_level" -gt "$BATTERY_HIGH_THRESHOLD" ]; then
        INFERENCE_LOCKED_BY_BATTERY=false
    fi

    if [ "$INFERENCE_LOCKED_BY_BATTERY" = true ]; then
        log "Battery level is below the unlock threshold (${BATTERY_HIGH_THRESHOLD}%), Inference remains stopped."
        manage_process "stop" "$PROCESS_PATTERN"
        sleep "$CHECK_INTERVAL"
        continue # Skip all other logic in this iteration
    fi

    # 2. Smart Evasion and CPU Management Logic
    cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//'); log "Current CPU usage: ${cpu_usage}%"
    is_running=$(check_process "$PROCESS_PATTERN" && echo true || echo false)

    # ==================== New: Smart Evasion Logic ====================
    if (( $(echo "$cpu_usage >= $CPU_THRESHOLD" | bc -l) )); then
        # ----- Enter High CPU Load Mode -----
        log "High CPU load mode: Activating smart evasion."
        if [ "$is_running" = true ]; then
            log "Inference is running, checking GPU to determine if there is a conflict..."
            gpu_power=$(get_gpu_power)
            log "Current GPU power: ${gpu_power}W"
            if (( $(echo "$gpu_power >= $GPU_POWER_THRESHOLD" | bc -l) )); then
                log "!!Conflict detected!! Both CPU and GPU are high! Immediately stopping Inference to make way for high-priority tasks."
                manage_process "stop" "$PROCESS_PATTERN"
            else
                log "No conflict: CPU is high, but GPU is idle. Letting Inference continue to run."
            fi
        else
            log "CPU is high, and Inference is not running. Maintaining the current state."
        fi
    else
        # ----- Enter Normal CPU Mode -----
        log "Normal CPU mode."
        if [ "$is_running" = false ]; then
            log "CPU is below the threshold and the process is not running. Preparing to start..."; 
            manage_process "start" "$PROCESS_PATTERN" "$START_COMMAND"
        else 
            # The process is running and the CPU is low, which means idle monitoring can be performed
            monitor_inference_process
        fi
    fi
    # =============================================================

    sleep "$CHECK_INTERVAL"
done
