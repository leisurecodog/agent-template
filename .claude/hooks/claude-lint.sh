#!/usr/bin/env bash
# PostToolUse single-file linter.
# 讀 hook 的 stdin JSON，取出被寫入的檔案路徑，依副檔名（與 claude-format.sh 同四類）
# 只對「單一檔案」跑 fast lint，不跑全 repo。
#   - sh/bash      → shellcheck
#   - tcl/tm       → tclsh info complete（純語法檢查，不執行內容）
#   - python       → ruff check
#   - C/C++ source → cppcheck（沒有才退 clang-tidy）；header 不單獨 lint
# linter 沒安裝時：不擋編輯（exit 0），改用 additionalContext 提示 Claude 用 brew 安裝，
#   每工具每天最多提示一次（state: .lint-missing-state，與本 script 同目錄）。
# 有 lint 錯誤才 exit 2，stderr 餵回 model 讓它下回合修。
# 只讀 stdin，永不執行收到的任何內容。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
input=$(cat)
f=$(printf '%s' "$input" | jq -r '.tool_response.filePath // .tool_input.file_path // .tool_input.filePath // empty')
[ -n "$f" ] && [ -f "$f" ] || exit 0

state="$SCRIPT_DIR/.lint-missing-state"
hint() { # $1 = 缺的工具, $2 = brew package
	command -v "$1" >/dev/null 2>&1 && return 0
	today=$(date +%Y-%m-%d)
	key="$1=$today"
	[ -f "$state" ] && grep -qxF "$key" "$state" 2>/dev/null && return 0
	printf '%s\n' "$key" >> "$state"
	printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"⚠️ claude-lint.sh：%s 未安裝，已跳過這檔的 lint。可執行 brew install %s 啟用。"}}\n' "$1" "$2"
	exit 0
}

case "$f" in
*.sh | *.bash)
	command -v shellcheck >/dev/null 2>&1 || { hint shellcheck shellcheck; exit 0; }
	out=$(shellcheck -f gcc -- "$f" 2>&1) || { printf '%s\n' "$out" >&2; exit 2; }
	;;
*.tcl | *.tm)
	command -v tclsh >/dev/null 2>&1 || exit 0
	# tclsh 沒有 -c；用 stdin heredoc，把檔案路徑嵌進 script 傳入。
	out=$(tclsh <<TCL 2>&1
set fp [open "$f" r]
set d [read \$fp]
close \$fp
if {![info complete \$d]} {puts stderr "tcl syntax incomplete"}
TCL
)
	[ -n "$out" ] && { printf '%s\n' "$out" >&2; exit 2; }
	;;
*.py | *.pyi)
	command -v ruff >/dev/null 2>&1 || { hint ruff ruff; exit 0; }
	out=$(ruff check --no-cache --output-format concise -- "$f" 2>&1) || { printf '%s\n' "$out" >&2; exit 2; }
	;;
*.c | *.cc | *.cpp | *.cxx)
	# header 不單獨 lint：沒有 translation unit，lint 沒有意義
	if command -v cppcheck >/dev/null 2>&1; then
		# --error-exitcode：cppcheck 預設找到問題也 exit 0，必須指定才回非零
		out=$(cppcheck --quiet --enable=warning,style --error-exitcode=1 "$f" 2>&1) || { printf '%s\n' "$out" >&2; exit 2; }
	elif command -v clang-tidy >/dev/null 2>&1; then
		out=$(clang-tidy --quiet "$f" -- 2>&1) || { printf '%s\n' "$out" >&2; exit 2; }
	else
		hint cppcheck cppcheck; exit 0
	fi
	;;
*)
	# 副檔名不認得：看 shebang。tclsh 必須排在 sh 前面（"#!/usr/bin/tclsh" 也結尾於 sh）。
	case "$(head -c 128 "$f" 2>/dev/null)" in
	'#!'*tclsh*)
		command -v tclsh >/dev/null 2>&1 || exit 0
		out=$(tclsh <<TCL 2>&1
set fp [open "$f" r]
set d [read \$fp]
close \$fp
if {![info complete \$d]} {puts stderr "tcl syntax incomplete"}
TCL
)
		[ -n "$out" ] && { printf '%s\n' "$out" >&2; exit 2; }
		;;
	'#!'*python*)
		command -v ruff >/dev/null 2>&1 || { hint ruff ruff; exit 0; }
		out=$(ruff check --no-cache --output-format concise -- "$f" 2>&1) || { printf '%s\n' "$out" >&2; exit 2; }
		;;
	'#!'*sh*)
		command -v shellcheck >/dev/null 2>&1 || { hint shellcheck shellcheck; exit 0; }
		out=$(shellcheck -f gcc -- "$f" 2>&1) || { printf '%s\n' "$out" >&2; exit 2; }
		;;
	esac
	;;
esac
exit 0
