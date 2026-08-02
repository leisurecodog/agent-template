# 制度維護協議

對象：未來所有 session（含較弱模型）。規定這套制度檔案怎麼安全地更新。
制度檔案 = 本 repo 的 `CLAUDE.md` ＋ `.claude/agent-docs/*.md` ＋ `.claude/rules/*.md`
＋ `.claude/settings.json`。個人記憶（使用者偏好、跨專案模式）寫回你自己的記憶機制。

## 1. 權限分級

### 可以自行改（不必問使用者）
- **事實修正**：檔名、路徑、工具名、model 名稱失效時，實查後更新為正確值。
  改之前必須實際驗證新值存在（`which`、`ls`、實際呼叫一次）。
- **新增教訓**到 `tasks/lessons.md`（見第 3 節）。
- **修錯字、修失效連結**。

### 動之前必須先問使用者
- 改 `CLAUDE.md` 的任何規則內容（事實修正除外）。
- 改 `judgment-rubrics.md` 的判準本身（門檻數字、必停清單）。
- 改 `model-dispatch.md` 的升降級路徑或重試上限。
- 改 `.claude/settings.json` 的 hooks 或其他設定。
- 刪除任何制度檔案或備份。

### 永遠不准做
- 把制度檔案的長內容搬回 CLAUDE.md 正文（CLAUDE.md 上限 80 行，保持精簡）。
- 無備份就覆寫制度檔案。
- 把 secrets（token、金鑰）寫進任何制度檔案或記憶。

## 2. 改檔標準流程

1. `mkdir -p .claude/backups/$(date +%Y-%m-%d)-<簡述> && cp <檔案> .claude/backups/$(date +%Y-%m-%d)-<簡述>/`。
2. 用 Edit 改（不要整檔重寫，除非結構性重構且已獲使用者同意）。
3. Read 回讀改動段落確認。
4. 在回覆中告知使用者改了什麼、為什麼。

## 3. 教訓寫回（雙層：repo 教訓 + 個人教訓）

被使用者糾正、或踩坑後發現可重用的模式時，先判斷教訓屬於哪一層：

**repo 相關教訓**（build／測試指令、專案 API、該 repo 特有的坑）：
- 位置：本 repo 的 `tasks/lessons.md`（不存在就建立）。
- 格式：標題 `# Project Learnings`，下分五個 section——Patterns That Work、
  Mistakes to Avoid、Domain Knowledge、Open Questions、Consolidated Principles；
  每條一行 `- [YYYY-MM-DD] 描述`，依教訓性質歸到對應 section。完整樣板見
  `.claude/agent-docs/templates/lessons-template.md`。

**個人教訓**（使用者偏好、環境非顯性事實、跨專案模式）：
- 位置：使用者自己的記憶機制（你的全域 memory 目錄，session 系統提示中會標示）。
- 格式：依該機制規定的格式（通常是 frontmatter 含 name／description／metadata.type，
  內文含 **Why:** 與 **How to apply:**，並在索引檔加一行）。
- 寫之前先查有沒有既有條目已涵蓋：有就更新它，不要開新的。發現錯誤的直接刪。

**什麼值得寫**：使用者的糾正與偏好、環境的非顯性事實（例如「某 API 有速率限制，
改用某替代」）、重複踩過的坑。
**什麼不值得寫**：repo 裡查得到的、只對本次對話有意義的、git history 已記錄的。

## 4. State 三件套（todo.md + lessons.md + progress.md）

State = 「下一個 session 要接續什麼」的記錄。分散在兩層：

**repo base（本 repo 的 `tasks/` 目錄，三件套）：**
- `todo.md`：進行中的事項與下一步。
- `lessons.md`：該 repo 的教訓（見第 3 節「repo 相關教訓」）。
- `progress.md`：跨 session 的開發進度——目前在哪個階段、下一步、驗收條件。
- 判準：**有跨 session 開發需求**的 repo 才需要三件套；無此需求的 repo 不建，
  避免每 repo 都背一套（違反「keep it small」）。

**user base（你的全域 state 檔）：**
- 追蹤跨 repo 或不屬任何 repo 的主線（harness 改進、研究、工具開發）。
- 不建 todo/learning——個人教訓在記憶機制，事項用各 repo 自己的機制。

**寫入時機**：任務跨 session、或做一半要收尾時，更新對應層的 progress.md。

## 5. 精簡時機（防止制度自己變成負擔）

- 記憶索引超過 **30 行** → 合併同類教訓、刪除已過時的。
- agent-docs 單檔超過 **400 行** → 把低頻內容抽到 `.claude/backups/` 或拆檔，路由表同步更新。
- 每次修改制度檔案時順手檢查：有沒有規則已經與現實不符（引用的工具、模型、skill
  還存在嗎）。發現就按第 1 節權限處理。
- 判斷衝突時的優先序：使用者當下指示 > CLAUDE.md > agent-docs > 記憶。
  發現兩檔規則打架：按優先序執行，並回報使用者請求裁決，裁決結果寫回檔案。
