#!/bin/bash
# Q6：将本地 Debian 包安装到 output/sysroot，运行安装后的工具。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

deb="$input/aim-sentry-tools.deb"
sysroot="$output/sysroot"

# 准备独立的安装根与其内部的 dpkg 安装数据库
mkdir -p "$sysroot/var/lib/dpkg"

# 以非 root 方式把包安装到 sysroot，不触碰真实系统根目录
dpkg --root="$sysroot" --force-not-root --log=/dev/null -i "$deb"

# 运行安装后的真实工具，记录标准输出
"$sysroot/usr/bin/aim-sentry-info" > "$output/tool-output.txt"
