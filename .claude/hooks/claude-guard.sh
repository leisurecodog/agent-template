#!/usr/bin/env bash
# PreToolUse safety guard.
# 讀 hook 的 stdin JSON，依 tool_name 分派檢查：
#   - Edit|Write：擋寫入 secrets 檔（.env、*.pem、*.key、憑證等）
#   - Bash：擋破壞性 rm（-rf 對到絕對路徑/~）與 git push
# exit 0 = 放行；exit 2 = 擋下，stderr 會回給 model 解釋原因。
# 只讀 stdin，永不執行收到的任何內容。

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')

case "$tool" in
Edit | Write)
	f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')
	[ -n "$f" ] || exit 0
	case "$f" in
	*.env | *.env.* | *secret* | *credential* | *.pem | *.key | *.p12 | *.pfx | .npmrc)
		echo "Protected file blocked: $f (secrets/credentials must be created manually)" >&2
		exit 2
		;;
	esac
	;;
Bash)
	cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
	[ -n "$cmd" ] || exit 0
	if printf '%s' "$cmd" | grep -qE '\brm\b.*-(fr|rf)' && printf '%s' "$cmd" | grep -qE '(^|[[:space:]])(/|~|\$HOME)'; then
		echo "Destructive rm blocked: rm -rf against absolute path or \$HOME" >&2
		exit 2
	fi
	if printf '%s' "$cmd" | grep -qE '\bgit[[:space:]]+push\b'; then
		echo "git push blocked: run it manually to confirm" >&2
		exit 2
	fi
	if printf '%s' "$cmd" | grep -qE '\bgit[[:space:]]+(reset[[:space:]]+--hard|checkout[[:space:]]+--?[[:space:]]+\.|clean[[:space:]]+-[a-z]*[fd]|stash[[:space:]]+(drop|clear))'; then
		echo "Destructive git blocked: $cmd (discards local work)" >&2
		exit 2
	fi
	;;
esac
exit 0
