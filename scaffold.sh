#!/usr/bin/env bash
# 把本模板複製成新專案骨架。
# 用法：scaffold.sh <目標目錄>
#   - 排除 .git、clones、backups 與 per-machine 產物（.codegraph/.opencode/.omo/.DS_Store）
#   - 以空 lessons.md 與 README 骨架取代模板自身產物
#   - git init 新專案（不自動 commit）
set -euo pipefail

TARGET="${1:?用法: scaffold.sh <目標目錄>}"
[ -e "$TARGET" ] && {
	echo "!! 目標已存在：$TARGET" >&2
	exit 1
}

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PDIR="${TARGET%/*}"
[ -n "$PDIR" ] || PDIR="."
mkdir -p "$PDIR"

# rsync 到同層暫存目錄再 mv：避免目標位於模板內時自我遞迴
STAGE="$(mktemp -d "$PDIR/.scaffold.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT

rsync -a \
	--exclude '.git' \
	--exclude '.claude/agent-feats/clones' \
	--exclude '.claude/backups' \
	--exclude '.codegraph' \
	--exclude '.opencode' \
	--exclude '.omc' \
	--exclude '.omo' \
	--exclude 'sync.log' \
	--exclude '.DS_Store' \
	"$SRC/" "$STAGE/"

# 模板自身產物換成空骨架
cat >"$STAGE/tasks/lessons.md" <<'EOF'
# Project Learnings

> 每條一行 `- [YYYY-MM-DD] 描述`。樣板見 `.claude/agent-docs/templates/lessons-template.md`。

## Patterns That Work

## Mistakes to Avoid

## Domain Knowledge

## Open Questions

## Consolidated Principles
EOF

cat >"$STAGE/README.md" <<'EOF'
# {專案名稱}

> 由 agent-template 產生。依專案調整本檔與 `CLAUDE.md`。

## 快速開始

1. 啟動 `claude`。
2. 依專案需求增刪 `.claude/rules/*.md`（非硬體專案刪 `hardware-*.md`）。
3. 教訓寫進 `tasks/lessons.md`。
EOF

mv "$STAGE" "$TARGET"
git -C "$TARGET" init -q

echo "== 已建立 ${TARGET}（git 已 init，未 commit）"
echo "下一步："
echo "  1. 調整 CLAUDE.md（專案特有路由、刪多餘規則）"
echo "  2. 確認 hooks 依賴後跑 ./check.sh 驗證"
