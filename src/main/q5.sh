#!/bin/bash
# Q5：运行 launch.env 给定的启动前检查，保存 stdout/stderr、真实退出码和诊断报告。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# 读取本题参数：LAUNCH_TOOL、MODEL_PATH、CAMERA_PATH
source "$input/launch.env"

# 实际调用检查程序，stdout 与 stderr 分开保存
if bash "$LAUNCH_TOOL" "$MODEL_PATH" "$CAMERA_PATH" \
    > "$output/stdout.log" 2> "$output/stderr.log"; then
    code=0
else
    code=$?
fi

# 记录真实退出码
printf '%d\n' "$code" > "$output/exit-code.txt"

# 依据真实退出状态判定结果，与 stderr 是否有内容无关
case "$code" in
    0)  result=SUCCESS; reason=NONE ;;
    10) result=FAILED;  reason=MODEL_MISSING ;;
    20) result=FAILED;  reason=CAMERA_DENIED ;;
    *)  result=FAILED;  reason=NONE ;;
esac

# 固定三行、固定顺序的诊断报告
printf 'result=%s\nexit_code=%s\nreason=%s\n' "$result" "$code" "$reason" > "$output/report.txt"

# 记录完成后正常退出，不因检查程序失败而提前停止
exit 0
