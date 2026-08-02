#!/usr/bin/env bash
# PostToolUse formatter dispatcher.
# 讀 hook 的 stdin JSON，取出被寫入的檔案路徑，先按副檔名分派；
# 副檔名認不出來時退回讀 shebang（deploy、configure、git hooks 這類無副檔名的腳本）。
# 找不到 formatter 就靜默跳過——hook 不該因為少裝工具而擋住編輯。
f=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty')
[ -n "$f" ] && [ -f "$f" ] || exit 0

# formatter 的抱怨不該出現在對話裡；壞掉的暫存檔格式化失敗是常態，不是錯誤。
exec 2>/dev/null

case "$f" in
*.sh | *.bash) command -v shfmt >/dev/null && shfmt -w -- "$f" ;;
*.tcl | *.tm) command -v tclfmt >/dev/null && tclfmt --in-place -- "$f" ;;
# --no-cache：否則 ruff 會在當前目錄留下 .ruff_cache/，污染別人的 repo。
*.py | *.pyi) command -v ruff >/dev/null && ruff format -q --no-cache -- "$f" ;;
*.c | *.cc | *.cpp | *.cxx | *.h | *.hh | *.hpp)
	command -v clang-format >/dev/null && clang-format -i --fallback-style=LLVM -- "$f"
	;;
*)
	# 副檔名不認得：看第一行 shebang。head -c 而非 read，避免無換行的巨大檔案整個吃進記憶體。
	# tclsh 必須排在 sh 前面——"#!/usr/bin/tclsh" 也結尾於 sh，順序顛倒會被 shfmt 接走。
	case "$(head -c 128 "$f")" in
	'#!'*tclsh*) command -v tclfmt >/dev/null && tclfmt --in-place -- "$f" ;;
	'#!'*python*) command -v ruff >/dev/null && ruff format -q --no-cache -- "$f" ;;
	'#!'*sh*) command -v shfmt >/dev/null && shfmt -w -- "$f" ;;
	esac
	;;
esac
exit 0
