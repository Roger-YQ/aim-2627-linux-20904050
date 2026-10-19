#!/bin/bash
# Bonus：start 时创建分离的 tmux 会话和采集器；stop 时正常停止采集器并结束会话。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-start}

source "$input/bonus.env"

log="$output/bonus.log"
# 采集器命令，路径与参数带引号，支持含空格的路径
collector="python3 $(printf '%q' "$WORKER_TOOL") --token $(printf '%q' "$TOKEN") --log $(printf '%q' "$log")"

# ------------------------------------------------------------------ stop ----
if [ "$action" = "stop" ]; then
    # 从日志中定位会话内采集器的进程号，正常停止它
    worker_pid=""
    if [ -f "$log" ]; then
        worker_pid=$(grep -o "pid=[0-9]*" "$log" 2>/dev/null | tail -n 1 | cut -d= -f2 || true)
    fi
    if [ -n "$worker_pid" ]; then
        kill -TERM "$worker_pid" 2>/dev/null || true
        attempt=0
        while [ "$attempt" -lt 20 ]; do
            if ! kill -0 "$worker_pid" 2>/dev/null; then
                break
            fi
            sleep 0.1
            attempt=$((attempt + 1))
        done
    fi
    # 再结束指定会话，不影响其他会话
    tmux -L "$TMUX_SOCKET" kill-session -t "$SESSION" 2>/dev/null || true
    exit 0
fi

# ----------------------------------------------------------------- start ----
# 会话不存在时才创建，保证全程只有一个采集器实例
if ! tmux -L "$TMUX_SOCKET" has-session -t "$SESSION" 2>/dev/null; then
    tmux -L "$TMUX_SOCKET" new-session -d -s "$SESSION" "$collector"
fi

# 确保返回后会话没有附着客户端
tmux -L "$TMUX_SOCKET" detach-client -s "$SESSION" 2>/dev/null || true

exit 0
