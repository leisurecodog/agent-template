#!/usr/bin/env bash
# 模板自檢：所有 shell script 的 bash -n 語法檢查 + shellcheck（已安裝則跑）。
# 用法：./check.sh
set -uo pipefail
cd "$(dirname "$0")" || exit 1

fails=0
scripts=()
while IFS= read -r s; do
	scripts+=("$s")
done < <(
	find . -name '*.sh' \
		! -path './.git/*' \
		! -path './.claude/agent-feats/clones/*' \
		! -path './.claude/backups/*' \
		! -path './.omc/*' \
		! -path './.opencode/*'
)

for s in "${scripts[@]}"; do
	if ! bash -n "$s"; then
		echo "!! bash -n 失敗: $s" >&2
		fails=$((fails + 1))
	fi
done

if command -v shellcheck >/dev/null 2>&1; then
	for s in "${scripts[@]}"; do
		if ! shellcheck -S warning "$s" >/dev/null; then
			echo "!! shellcheck 告警: $s" >&2
			fails=$((fails + 1))
		fi
	done
else
	echo "-- shellcheck 未安裝，僅語法檢查（brew install shellcheck 後重跑）"
fi

if [ "$fails" -eq 0 ]; then
	echo "OK：${#scripts[@]} 支 script 檢查通過。"
else
	echo "! ${fails} 支 script 有問題，見上方明細。" >&2
	exit 1
fi
