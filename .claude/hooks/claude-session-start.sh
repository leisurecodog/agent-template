#!/usr/bin/env bash
# SessionStart hook: 開新 session 時注入簡潔狀態摘要（repo 髒狀態、待審提案、未完成 tasks）。
# 只在真正的 startup（新 session）輸出，避免 auto_compact / resume / clear 重複噪音。
# 永遠 exit 0 —— 摘要只是額外 context，不能阻擋 session 開始。
#
# 重要：macOS 系統 bash 3.2 對「中文 literal + 變數展開」同一個雙引號字串有
# UTF-8 處理 bug（變數內容會壞成 U+FFFD）。一律用 printf 分欄位組字串，變數當 arg。

exec 2>/dev/null

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
source_kind=$(printf '%s' "$input" | jq -r '.source // empty')
[ "$source_kind" != "startup" ] && exit 0
[ -n "$cwd" ] && [ -d "$cwd" ] || exit 0

# 1. git 狀態
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
	branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
	n_changes=$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
	if [ "$n_changes" -gt 0 ]; then
		printf '[SessionStart] 注意：repo %s 在分支 %s，有 %s 個未 commit 變更，動手前先確認是否要提交。\n' "$repo_root" "$branch" "$n_changes"
	else
		printf '[SessionStart] git: %s 在分支 %s，工作區乾淨。\n' "$repo_root" "$branch"
	fi
else
	printf '[SessionStart] 目前不在 git repo 內（cwd=%s）。\n' "$cwd"
fi

# 2. 待審元件提案（專案內 .claude/proposals.md，不存在就略過）
proposals=""
if [ -n "${repo_root:-}" ] && [ -f "$repo_root/.claude/proposals.md" ]; then
	proposals="$repo_root/.claude/proposals.md"
elif [ -f "$cwd/.claude/proposals.md" ]; then
	proposals="$cwd/.claude/proposals.md"
fi
if [ -n "$proposals" ] && [ -s "$proposals" ]; then
	n=$(grep -c '^## ' "$proposals" 2>/dev/null || true)
	if [ "${n:-0}" -gt 0 ]; then
		first_title=$(grep '^## ' "$proposals" | head -1 | sed 's/^## //')
		printf '[SessionStart] 有 %s 則待審元件提案（%s），最新一則：%s。\n' "$n" "$proposals" "$first_title"
	fi
fi

# 3. 未完成的 tasks 接續
if [ -n "${repo_root:-}" ] && [ -f "$repo_root/tasks/progress.md" ]; then
	printf '[SessionStart] 發現 %s 存在，可能有未完成的工作待接續，先看一眼再開始。\n' "$repo_root/tasks/progress.md"
fi

exit 0
