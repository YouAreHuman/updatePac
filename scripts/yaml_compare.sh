#!/bin/bash

# yaml_compare.sh - 比较两个 YAML 文件内容是否相同

set -euo pipefail

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项] <文件1> <文件2>

比较两个 YAML 文件的内容是否相同（忽略格式差异，只比较语义）。

选项:
    -h, --help     显示此帮助信息
    -s, --strict   严格模式：逐字节比较（不推荐用于 YAML）
    -v, --verbose  详细输出

依赖:
    yq (https://github.com/mikefarah/yq) - 用于解析和标准化 YAML

EOF
}

# 默认参数
STRICT_MODE=false
VERBOSE=true

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--strict)
            STRICT_MODE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            echo "未知选项: $1" >&2
            show_help >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# 检查参数数量
if [[ $# -ne 2 ]]; then
    echo "错误: 需要指定两个文件" >&2
    show_help >&2
    exit 1
fi

FILE1="$1"
FILE2="$2"

# 检查文件是否存在
if [[ ! -f "$FILE1" ]]; then
    echo "错误: 文件 '$FILE1' 不存在" >&2
    exit 1
fi

if [[ ! -f "$FILE2" ]]; then
    echo "错误: 文件 '$FILE2' 不存在" >&2
    exit 1
fi

# 严格模式：直接比较文件
if [[ "$STRICT_MODE" == true ]]; then
    if cmp -s "$FILE1" "$FILE2"; then
        [[ "$VERBOSE" == true ]] && echo "文件完全相同（逐字节比较）"
        exit 0
    else
        [[ "$VERBOSE" == true ]] && echo "文件不同（逐字节比较）"
        exit 1
    fi
fi

# 检查 yq 是否安装
if ! command -v yq &> /dev/null; then
    echo "错误: 需要安装 yq 工具" >&2
    echo "安装方法:" >&2
    echo "  Linux/macOS: https://github.com/mikefarah/yq#install" >&2
    echo "  或使用包管理器: brew install yq" >&2
    exit 1
fi

# 检查 yq 版本（需要 v4+）
YQ_VERSION=$(yq --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
if [[ -z "$YQ_VERSION" ]]; then
    echo "警告: 无法检测 yq 版本，继续执行..." >&2
else
    MAJOR_VER=$(echo "$YQ_VERSION" | cut -d. -f1)
    if [[ "$MAJOR_VER" -lt 4 ]]; then
        echo "错误: 需要 yq v4 或更高版本，当前版本: $YQ_VERSION" >&2
        exit 1
    fi
fi

# 使用 yq 标准化并比较 YAML 内容
# yq eval 将 YAML 转换为标准格式（排序键、统一缩进等）
NORMALIZED_1=$(yq eval '.' "$FILE1" 2>/dev/null)
NORMALIZED_2=$(yq eval '.' "$FILE2" 2>/dev/null)

# 检查 yq 是否成功解析
if [[ $? -ne 0 ]]; then
    echo "错误: 无法解析 YAML 文件，请检查文件格式" >&2
    exit 1
fi

# 比较标准化后的内容
if [[ "$NORMALIZED_1" == "$NORMALIZED_2" ]]; then
    [[ "$VERBOSE" == true ]] && echo "YAML 内容相同"
    exit 0
else
    if [[ "$VERBOSE" == true ]]; then
        echo "YAML 内容不同"
        echo "差异详情:"
        diff <(echo "$NORMALIZED_1") <(echo "$NORMALIZED_2")
    fi
    exit 1
fi
