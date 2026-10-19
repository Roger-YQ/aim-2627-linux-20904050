#!/bin/bash
# Q4：合并日志，按级别提取，保存首尾片段并统计错误行数。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

all="$output/all.log"

# 1. 按 boot、run 顺序完整拼接
cat "$input/boot.log" "$input/run.log" > "$all"

# 2. 级别字段等于 ERROR 的完整行；无匹配时正常产生空文件
grep "^ERROR " "$all" > "$output/errors.log" || true

# 3. 级别字段等于 WARN 或 ERROR 的完整行
grep -E "^(WARN|ERROR) " "$all" > "$output/attention.log" || true

# 4. 合并结果最后 5 行，不足则全部
tail -n 5 "$all" > "$output/recent.log"

# 5. 错误结果最前 3 行，不足则全部
head -n 3 "$output/errors.log" > "$output/first-errors.log"

# 6. 错误行数，只有整数与换行
count=$(grep -c "^ERROR " "$all" || true)
printf '%d\n' "$count" > "$output/error-count.txt"
