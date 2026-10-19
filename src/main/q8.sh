#!/bin/bash
# Q8：repair 时识别并停止采集器、修复 HTTP 服务；cleanup 时停止修复后的服务。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-repair}

source "$input/process.env"

service_dir="$output/service"

# ---------------------------------------------------------------- cleanup ----
if [ "$action" = "cleanup" ]; then
    # 依据本题服务状态目录定位修复后的服务，正常停止它
    if [ -f "$service_dir/pid" ]; then
        service_pid=$(tr -d '[:space:]' < "$service_dir/pid")
        if [ -n "$service_pid" ]; then
            kill -TERM "$service_pid" 2>/dev/null || true
            attempt=0
            while [ "$attempt" -lt 20 ]; do
                if ! kill -0 "$service_pid" 2>/dev/null; then
                    break
                fi
                sleep 0.1
                attempt=$((attempt + 1))
            done
        fi
    fi
    exit 0
fi

# ----------------------------------------------------------------- repair ----
# A1. 记录目标采集器的识别信息
pid_value=$(ps -o pid= -p "$TARGET_PID" | tr -d '[:space:]')
uid_value=$(ps -o uid= -p "$TARGET_PID" | tr -d '[:space:]')
state_value=$(ps -o stat= -p "$TARGET_PID" | tr -d '[:space:]')
command_value=$(ps -o args= -p "$TARGET_PID")
user_value=$(getent passwd "$uid_value" | cut -d: -f1 || true)
if [ -z "$user_value" ]; then
    user_value=$(ps -o user= -p "$TARGET_PID" | tr -d '[:space:]')
fi
printf 'pid=%s\nuser=%s\nstate=%s\ncommand=%s\n' \
    "$pid_value" "$user_value" "$state_value" "$command_value" > "$output/process.txt"

# A2. 保存目标采集器的日志样本（至少两条 TICK）
tail -n 5 "$WORKER_LOG" > "$output/collector-sample.log"

# A3. 向目标 PID 发送终止信号并等待正常退出，不使用 killall 或宽泛 pkill
kill -TERM "$TARGET_PID" 2>/dev/null || true
attempt=0
while [ "$attempt" -lt 20 ]; do
    if ! kill -0 "$TARGET_PID" 2>/dev/null; then
        break
    fi
    sleep 0.1
    attempt=$((attempt + 1))
done

# B1. 停止原错误服务
kill -TERM "$SERVICE_PID" 2>/dev/null || true
attempt=0
while [ "$attempt" -lt 20 ]; do
    if ! kill -0 "$SERVICE_PID" 2>/dev/null; then
        break
    fi
    sleep 0.1
    attempt=$((attempt + 1))
done

# B2. 生成修复后的服务配置
printf 'bind=127.0.0.1\nport=%s\nroute=/status\n' "$TARGET_PORT" > "$output/server.conf"

# B3. 使用教师启动工具运行修复后的服务
bash "$START_TOOL" "$output/server.conf" "$service_dir"

# B4. 有界重试等待就绪，再请求 /status
url="http://127.0.0.1:$TARGET_PORT/status"
status=000
attempt=0
while [ "$attempt" -lt 30 ]; do
    status=$(curl -s -o "$output/http-body.txt" -w '%{http_code}' --max-time 2 "$url" || true)
    if [ "$status" = "200" ]; then
        break
    fi
    sleep 0.2
    attempt=$((attempt + 1))
done
printf '%s\n' "$status" > "$output/http-status.txt"

# repair 返回时保留服务运行，交由教师独立请求
exit 0

