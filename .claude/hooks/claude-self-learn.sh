#!/usr/bin/env bash
# Stop self-learning hook.
# 每輪 Stop 觸發。先做輕量成本檢查（該輪 transcript 是否含失敗/錯誤訊號），
# 有訊號才呼叫 headless claude -p 萃取教訓。
# 教訓分兩層：repo 相關 → <repo_root>/tasks/learnings.md；使用者個人 → 固定
# ~/.claude/projects/<由 $HOME 推得>/memory/（不隨啟動 cwd 分散）。
# 混合視野：該輪 transcript 為主；每 10 個錯誤輪次做一次全景。
# 永遠 exit 0 —— 學習是副作用，不能阻擋或拖慢回應。

# 巢狀抑制：本 script 被自己的 claude -p 子行程觸發時（會繼承 env），
# 直接退出，避免 Stop → claude -p → Stop 的無限遞迴。
[ -n "$CLAUDE_SELF_LEARN_SUPPRESS" ] && exit 0

exec 2>/dev/null

input=$(cat)
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
transcript_path=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
last_msg=$(printf '%s' "$input" | jq -r '.last_assistant_message // empty')

[ -n "$transcript_path" ] && [ -f "$transcript_path" ] || exit 0

# repo 教訓 → <repo_root>/tasks/learnings.md（依 git root 定位）
repo_root=""
if git -C "$cwd" rev-parse --show-toplevel >/dev/null 2>&1; then
	repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
fi
if [ -n "$repo_root" ]; then
	tasks_dir="$repo_root/tasks"
else
	tasks_dir=""
fi
# 個人教訓 → 固定單一位置，由 $HOME 推得（換機/換使用者名自動對應），不隨啟動 cwd 分散
mem_key="-$(printf '%s' "$HOME" | sed 's|^/||; s|/|-|g; s|_|-|g; s|\.|-|g')"
mem_dir="$HOME/.claude/projects/$mem_key/memory"
mkdir -p "$mem_dir" 2>/dev/null
[ -n "$tasks_dir" ] && mkdir -p "$tasks_dir" 2>/dev/null

# 節流狀態檔：記錄上次跑的輪次與全景計數
state="$HOME/.claude/scripts/.self-learn-state"
last_turn=0
last_full=0
if [ -f "$state" ]; then
	# shellcheck disable=SC1090
	source "$state"
fi

# 判斷該輪是否有失敗訊號：transcript 尾部近 2000 行找 tool 錯誤
error_signal=0
tail -n 2000 "$transcript_path" | grep -qiE 'PostToolUseFailure|"is_error": *true|"success": *false|error|failed|denied|exit.?code.?[1-9]' && error_signal=1
# 最後一則 assistant 訊息含錯誤口吻也算
printf '%s' "$last_msg" | grep -qiE 'failed|error|錯誤|失敗|抱歉|對不起' && error_signal=1

turn_marker="${session_id}"
[ "$turn_marker" != "$last_turn" ] && last_full=$((last_full + 1))
# 沒錯誤訊號就完全不出發 headless
if [ "$error_signal" -eq 0 ]; then
	printf 'last_turn="%s"\nlast_full=%s\n' "$turn_marker" "$last_full" >"$state"
	exit 0
fi

scope="該輪"
if [ "$last_full" -ge 10 ]; then
	scope="全景"
	last_full=0
fi
printf 'last_turn="%s"\nlast_full=%s\n' "$turn_marker" "$last_full" >"$state"

# 呼叫 headless claude 萃取教訓，只回結構化文字，不自己寫檔
# 寫入目標與格式的規範來源：~/.claude/commands/learnings-update.md（單一基準）。
# 本 prompt 只注入動態路徑（$tasks_dir / $mem_dir）取代命令內屬於本互動的具體位置，
# 其餘目標與格式規則照 learnings-update.md 執行。
#
# 2026-08-02 修正：曾發現子行程不一定照 prompt 文字指示寫檔，而是改用它自己那次啟動
# 的內建 auto-memory（按它自己的 cwd 編碼），導致個人教訓誤寫進某個 repo 的 memory/
# 而非這裡算好的固定 $mem_dir（詳見個人記憶 headless-claude-p-ignores-path-instructions）。
# 修法：用 --disallowedTools 完全禁用 Write/Edit/NotebookEdit，讓子行程物理上不可能寫
# 任何檔案（含它自己的 auto-memory，內部也是靠 Write 工具），只能回傳結構化文字；
# 實際寫檔改由本 script 用 shell 直接寫到算好的路徑，路徑不再假手子行程。
# 不用 --bare：它會停用 keychain reads 導致 claude.ai 登入失效，副作用比省下的 tokens 貴。
if [ -n "$tasks_dir" ]; then
	task_hint="這個互動發生在 git repo：$repo_root。repo 相關教訓的目標檔：$tasks_dir/learnings.md。"
else
	task_hint="這個互動不在 git repo 內，沒有 repo 專屬 tasks 目錄，所有教訓都屬個人。"
fi
prompt="你是 session 的教訓萃取器。以下是一段 Claude Code transcript（$scope 視野）。

作業：依【learnings-update 規範】判斷這次互動裡有沒有值得寫進長期記憶的可重用教訓。你**沒有
Write/Edit 工具**，不能自己寫檔（包含你自己的 auto-memory 機制），只能讀（Read/Glob/Grep）既有
檔案做重複檢查，並把結果以下面的**結構化文字格式**回覆，由外層程式碼負責實際寫檔。

learnings-update 規範：
- Repo-specific（只對這個 repo：程式結構、build/測試指令、坑、API、環境、特定檔案） → 該 repo 的 tasks/learnings.md（5 sections: Patterns That Work / Mistakes to Avoid / Domain Knowledge / Open Questions / Consolidated Principles；一行 - [YYYY-MM-DD] 條目；Mistakes 條必含怎麼避免再犯）。本次目標檔：$tasks_dir/learnings.md
- Personal（跨專案：使用者偏好、工作習慣、跨 repo 環境事實、通用工作流） → 一檔一教訓，檔名 kebab-case；frontmatter 含 name、description、metadata.type(user|feedback|project|reference)；內文 Why: 與 How to apply:。目標目錄：$mem_dir（先讀 $mem_dir/MEMORY.md 與既有檔，查有否已涵蓋，有就在回覆裡給『更新後的完整內容』而非另開新檔）

$task_hint

然後遵守：
1. 沒有值得寫的教訓就只回：ACTION: NONE
2. 一次只處理最重要的 1 條；不要重複給 repo 與個人各一條，只給最有價值那條。
3. 回覆格式（沒有教訓時只有第 1 行，不要有其他內容）：

ACTION: NONE
（或）
ACTION: WRITE_REPO
<<<FILE_CONTENT_START>>>
<tasks/learnings.md 更新後的完整檔案內容>
<<<FILE_CONTENT_END>>>
（或）
ACTION: WRITE_PERSONAL
FILENAME: <kebab-case-name>.md
INDEX_LINE: - [標題](<kebab-case-name>.md) — 一句話
<<<FILE_CONTENT_START>>>
<該教訓檔更新後的完整內容，含 frontmatter>
<<<FILE_CONTENT_END>>>

4. 元件化提案（額外產出，不取代上面的教訓）：若這條教訓「夠通用且行為化」（形如「以後每次做 X 都先做 Y」、會改變使用者未來工作方式），在 ACTION 區塊結束後另起一段輸出：
   PROPOSAL
   類型: rule | command | skill | hook
   標題: <一句話>
   檔名: <建議檔名>
   掛載位置: <具體建議，例如「CLAUDE.md 路由表加一行」/「~/.claude/scripts/ 新 script」/「~/.claude/skills/<name>/SKILL.md」>
   內容大綱: <3-5 行，具體到能直接照>
   理由: <為什麼值得做成元件，而非只寫記憶>
   不確定該不該做 → 不要輸出 PROPOSAL。

Transcript 內容：
$(if [ "$scope" = "全景" ]; then cat "$transcript_path"; else tail -n 2000 "$transcript_path"; fi)"

result=$(printf '%s' "$prompt" | CLAUDE_SELF_LEARN_SUPPRESS=1 claude -p --output-format text --disallowedTools "Write,Edit,NotebookEdit" 2>/dev/null)
[ -z "$result" ] && exit 0

action=$(printf '%s\n' "$result" | sed -n '1p' | sed 's/^ACTION: *//')

extract_block() {
	# 印出 <<<FILE_CONTENT_START>>> 與 <<<FILE_CONTENT_END>>> 之間的內容
	printf '%s\n' "$result" | sed -n '/^<<<FILE_CONTENT_START>>>$/,/^<<<FILE_CONTENT_END>>>$/p' |
		sed '1d;$d'
}

case "$action" in
WRITE_REPO)
	if [ -n "$tasks_dir" ]; then
		content=$(extract_block)
		if [ -n "$content" ]; then
			printf '%s\n' "$content" >"$tasks_dir/learnings.md"
			printf '%s\n' "[$(date '+%F %T')] repo: $tasks_dir/learnings.md" >>"$HOME/.claude/scripts/.self-learn-log"
		fi
	fi
	;;
WRITE_PERSONAL)
	filename=$(printf '%s\n' "$result" | sed -n '/^FILENAME: */p' | head -1 | sed 's/^FILENAME: *//')
	index_line=$(printf '%s\n' "$result" | sed -n '/^INDEX_LINE: */p' | head -1 | sed 's/^INDEX_LINE: *//')
	content=$(extract_block)
	if [ -n "$filename" ] && [ -n "$content" ]; then
		printf '%s\n' "$content" >"$mem_dir/$filename"
		# MEMORY.md 索引：同檔名已有索引行就取代，否則附加；沒有 MEMORY.md 就先建
		mem_index="$mem_dir/MEMORY.md"
		[ -f "$mem_index" ] || printf '# Memory Index\n\n' >"$mem_index"
		if [ -n "$index_line" ]; then
			if grep -qF "]($filename)" "$mem_index"; then
				esc_filename=$(printf '%s' "$filename" | sed 's/[.[\*^$/]/\\&/g')
				sed -i '' "s|^-.*\](${esc_filename}).*$|${index_line//|/\\|}|" "$mem_index" 2>/dev/null
			else
				printf '%s\n' "$index_line" >>"$mem_index"
			fi
		fi
		printf '%s\n' "[$(date '+%F %T')] personal: $mem_dir/$filename" >>"$HOME/.claude/scripts/.self-learn-log"
	fi
	;;
esac

proposal=$(printf '%s\n' "$result" | sed -n '/^PROPOSAL/,$p')
if [ -n "$proposal" ]; then
	{
		printf '\n## %s\n' "$(date '+%F %T')"
		printf 'repo: %s\n' "${repo_root:-無}"
		printf '%s\n' "---"
		printf '%s\n' "$proposal"
	} >>"$HOME/.claude/proposals.md"
fi
exit 0
