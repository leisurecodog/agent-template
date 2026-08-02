# Rules 使用說明（使用者層 `~/.claude/rules/` 與 repo 層 `.claude/rules/`）

> 本檔是機制說明，不是規則本文。

## Rules 是什麼

Rules 是你寫給 Claude 的「規定清單」：告訴它在這個環境／專案裡怎麼寫程式、
什麼事情不能做、要遵守哪些規範。

## 載入行為（關鍵細節）

不是所有 rules 都無腦全讀：

- **沒有 `paths:` frontmatter** → session 開始就載入（等同 CLAUDE.md 的優先度）。
- **有 `paths:` frontmatter** → 只在 Claude 真正處理到符合路徑的檔案時才載入。

這就是 rules 適合大型專案的原因：可以把上下文切得很精準，
不會每次都把整包規範塞進來。

## 與其他層級的分工

| 層級 | 用途 | 載入時機 |
|---|---|---|
| 使用者層 `~/.claude/CLAUDE.md` | 每次都要遵守、夠短的核心規則 | 自動 |
| repo 層 `CLAUDE.md` | 該專案每次都要遵守的核心規則 | 自動 |
| `~/.claude/rules/*.md` 或 `.claude/rules/*.md`（無 paths） | 全域／專案、但希望獨立成檔的規則 | session 啟動 |
| 同上（有 paths） | 只在特定檔案類型才需要的規則 | 讀到匹配檔案 |
| `~/.claude/agent-docs/*.md` 或 `.claude/agent-docs/*.md` | 長內容／模板／參考，需要時才 Read | 按需 |

## 目前狀態（本模板）

- 已建：`.claude/rules/python.md`（`paths: "**/*.py"`）、`.claude/rules/c++.md`
  （`paths: "**/*.cpp"` 等 C/C++ 檔），實測讀對應檔案才載入。
- coding-rules.md 的結構／邊界／測試／動手前已移植進 python.md／c++.md；
  Git 段留在 coding-rules.md（通用行為規則，無路徑維度，按需讀較合理）。

## 決策原則

判斷某規則該放哪：**這個規則是否每次都會用到、且不能依賴 agent 記得去讀？**
- 是 → CLAUDE.md 或無 paths 的 rules
- 只在特定檔案類型需要 → 有 paths 的 rules
- 需要時才看的長內容／參考 → agent-docs
