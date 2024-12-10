#!/bin/bash

# 设置变量
WORKER_ID=***  # 您的worker_id
CODE_ID=***  # 您的code_id
KUZCO_PATH="/usr/local/bin/kuzco"    # 假设kuzco在用户根目录下
LOG_FILE="$HOME/kuzco_monitor.log"
CPU_THRESHOLD=30            # CPU使用率的阈值
CHECK_INTERVAL=5            # 检查CPU使用率的时间间隔，单位秒

# 记录日志的函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 检查kuzco是否正在运行
is_kuzco_running() {
    pgrep -f "$KUZCO_PATH worker start --worker $WORKER_ID --code $CODE_ID" > /dev/null
}

# 启动kuzco的函数，捕获并记录输出
start_kuzco() {
    if ! is_kuzco_running; then
        log "Attempting to start kuzco with worker ID: $WORKER_ID and code ID: $CODE_ID"
        
        # 启动kuzco并捕获输出
        nohup "$KUZCO_PATH" worker start --worker $WORKER_ID --code $CODE_ID > "$HOME/kuzco_output.log" 2>&1 &
        
        # 等待几秒以检查进程是否启动成功
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

# 停止kuzco的函数
stop_kuzco() {
    if is_kuzco_running; then
        log "Attempting to stop kuzco."
        pkill -f "$KUZCO_PATH worker start --worker $WORKER_ID --code $CODE_ID"

        # 等待几秒以确保进程停止
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

# 获取当前CPU使用率的函数
get_cpu_usage() {
    top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//'
}

# 主循环，实时监控CPU使用率并控制kuzco的启停
while true; do
    cpu_usage=$(get_cpu_usage)

    log "Current CPU usage: ${cpu_usage}%"

    # 根据CPU使用率决定启动或停止kuzco
    if (( $(echo "$cpu_usage < $CPU_THRESHOLD" | bc -l) )); then
        log "CPU usage below threshold. Attempting to start kuzco."
        start_kuzco
    else
        log "CPU usage above threshold. Stopping kuzco if running."
        stop_kuzco
    fi

    # 等待指定的检查间隔
    sleep "$CHECK_INTERVAL"
done