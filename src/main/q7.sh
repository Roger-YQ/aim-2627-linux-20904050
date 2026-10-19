#!/bin/bash
# Q7：读取 input/remote.env，生成 ssh_config，用 SSH 和 SCP 获取远程数据。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# 读取本题参数：HOST、PORT、REMOTE_USER、KEY_PATH、KNOWN_HOSTS、REMOTE_LOG
source "$input/remote.env"

mkdir -p "$output/received"
config="$output/ssh_config"

# 1. 生成仅本人可读的 SSH 客户端配置，别名 aim-sentry
{
    printf 'Host aim-sentry\n'
    printf '    HostName %s\n' "$HOST"
    printf '    Port %s\n' "$PORT"
    printf '    User %s\n' "$REMOTE_USER"
    printf '    IdentityFile "%s"\n' "$KEY_PATH"
    printf '    UserKnownHostsFile "%s"\n' "$KNOWN_HOSTS"
    printf '    IdentitiesOnly yes\n'
    printf '    StrictHostKeyChecking yes\n'
    printf '    BatchMode yes\n'
} > "$config"
chmod 600 "$config"

# 2. 用该配置和别名执行远端 whoami
ssh -F "$config" aim-sentry whoami > "$output/remote-user.txt"

# 3. 用 SCP 下载远端日志
scp -F "$config" "aim-sentry:$REMOTE_LOG" "$output/received/errors.log"
