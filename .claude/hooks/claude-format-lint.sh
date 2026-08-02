#!/usr/bin/env bash
# PostToolUse：先 format 後 lint（同一個 hook 依序跑）。
# 原本 claude-format.sh 與 claude-lint.sh 是平行執行、會同時讀寫同一檔案造成 race；
# 改成 wrapper 串接，format 完成後 lint 才讀已格式化內容。
# 最後的 exit code 是 lint 的：lint 有錯 exit 2（餵回 model），format 恆 exit 0。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

input=$(cat)
printf '%s' "$input" | "$SCRIPT_DIR/claude-format.sh"
printf '%s' "$input" | "$SCRIPT_DIR/claude-lint.sh"
