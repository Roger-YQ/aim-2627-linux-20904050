#!/bin/bash
# Q3：复制素材、备份配置、移动草稿、删除 tmp、设定权限并直接运行 hello.sh。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

ws="$output/sentry_ws"

# 1. 建立工作区目录结构
mkdir -p "$ws/scripts" "$ws/config" "$ws/backup" "$ws/archive"

# 2. 复制脚本与两份配置到对应目录（源素材保持只读，不被修改）
cp "$input/hello.sh" "$ws/scripts/hello.sh"
cp "$input/robot.conf" "$ws/config/robot.conf"
cp "$input/draft.conf" "$ws/config/draft.conf"

# 3. 在 backup/ 保存正式配置的完整副本
cp "$ws/config/robot.conf" "$ws/backup/robot.conf"

# 4. 将草稿移动并改名到 archive/，原位置不再保留
mv -f "$ws/config/draft.conf" "$ws/archive/draft.conf.old"

# 5. 删除整个 tmp/，清理上次运行留下的缓存
rm -rf "$ws/tmp"

# 6. 设定精确权限：脚本 750，正式配置 640
chmod 750 "$ws/scripts/hello.sh"
chmod 640 "$ws/config/robot.conf"

# 7. 直接执行工作区中的脚本，记录标准输出
"$ws/scripts/hello.sh" > "$output/hello-output.txt"
