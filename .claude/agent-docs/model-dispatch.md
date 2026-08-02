# 模型調度守則

> 本檔的模型名稱（`haiku`/`sonnet`/`opus`/`fable`）與 agent type
> （`Explore`/`general-purpose`/`gemini:researcher`）是 Claude Code 的命名。
> 換平台或訂閱時，把這些名稱對應到你實際可用的 model 等級與 subagent 類型即可，
> 結構與門檻不變。

適用對象：每一個擔任「主對話」的模型，不論等級。
本檔是使用者的**常設授權**：符合下述條件時直接派 subagent，不需要再徵求同意。
harness 內建的「Do not spawn agents unless the user asks」以本檔為準——使用者已經 ask 了，就是這份檔案。

## 1. 指揮官不下場

主對話的職責是規劃、派工、整合、對使用者說話。以下工作**一律派 subagent**，
主對話只收結論：

| 工作型態 | 判準（任一成立就派） | 派給誰 |
|---|---|---|
| 找檔案、找定義、找引用 | 位置完全未知，或預期要試多輪關鍵字 | `Explore`（快、唯讀）；已知大概位置的單次 grep 自己做 |
| 大量讀取／掃 repo | 預估要讀超過 5 個檔或超過 2000 行 | `Explore` 或 `general-purpose` |
| 網路研究、查證事實 | 需要超過 2 次網路查詢 | `gemini:researcher`（有 Google 搜尋）或 `general-purpose` |
| 批次改檔 | 同一模式要套用到 3 個以上檔案 | `general-purpose`，model 用 `haiku`（模式已明確時）或 `sonnet` |
| 實作一個獨立功能 | 改動範圍明確、可獨立驗收 | `general-purpose`，model 用 `sonnet` |
| 驗收別人（或自己）的產出 | 見第 6 節 | fresh 的 `general-purpose` |

主對話**可以自己做**的事：讀 1–3 個已知路徑的檔案、跑單一指令、小型編輯、
與使用者對話。不要為了 30 秒的事開 agent——agent 冷啟動要重新建立 context。

## 2. 派工四件套（缺一不發）

每個 Agent prompt 必含四段（模板見 `delegation-templates.md`）：

1. **目標與動機**：要做什麼、為什麼做（動機讓 agent 遇到邊角情況時能自行做對的取捨）。
2. **驗收條件**：可機械檢查的完成定義。「測試 X 通過」「檔案 Y 存在且包含 Z 段落」，
   不是「做好」「弄乾淨」。
3. **停止條件**：重試上限、證據門檻、換路時機——什麼情況該停手回報、不要硬撐
   （見第 5 節與 `prompting-principles.md` 原則 4）。
4. **回報格式**：明確規定回什麼、不回什麼（見第 4 節）。

## 3. 顯式指定 model

Agent tool 的 `model` 參數只接受四個值：`haiku`、`sonnet`、`opus`、`fable`。
每次派工都**顯式指定**，不要留空吃預設。

| model | 用途 | 例子 |
|---|---|---|
| `haiku` | 機械式工作：格式轉換、已定義模式的批次套用、簡單抽取 | 「把這 8 個檔案的 import 改成新路徑，模式如下…」 |
| `sonnet` | 預設主力：搜尋、實作、重構、一般研究、審查 | 絕大多數派工 |
| `opus` | 深度推理：架構取捨、sonnet 連錯兩次的難 bug、品味判斷 | 「這兩種 schema 設計選哪個，考慮未來擴充」 |
| `fable` | 只在兩種情況：使用者明示，或升級鏈頂端（opus 也失敗，**且已先問過使用者**，見第 5 節） | 罕用，成本最高 |

**effort-first、tier-second**：現代模型（Claude `effort`、OpenAI `reasoning_effort`、
GLM `reasoning_effort`）把思考深度當成**一等旋鈕**，不是靠 prompt 硬催。需要更深的推理時，
**先調高 effort**（agent 定義檔 frontmatter 或平台全域設定）——升 effort 比升 model 便宜；
effort 已到頂或不支援，才換 model 等級。Agent tool 沒有 per-call 的 effort 參數，
若要對單一任務調 effort：先調平台全域 effort，或換 model 等級。
不要用 prompt 寫「請深入推理」／「快速完成即可」代替 effort（原則見
`prompting-principles.md` 原則 1）。

## 4. 回報合約

寫進每個派工 prompt 的固定段落：

> 回報規則：只回報結論、關鍵發現、以及 `檔案路徑:行號` 形式的位置引用。
> 超過 30 行的產出（報告、程式碼、清單）寫入檔案，只回傳檔案路徑。
> 不要把讀到的檔案內容整段貼回。不要重述任務本身。
> 若失敗：回報你試了什麼、卡在哪、以及你建議的下一步。

主對話收到回報後：把對使用者有意義的部分轉述給使用者，不要只說「agent 完成了」。

## 5. 升降級路徑

- **第 0 步：先升 effort，再升 model**。需要更強推理時，先確認該 model 的
  effort 是否已調到頂（見 §3）；還沒到頂就升 effort，不要直接跳 model 等級。
- **haiku 錯 1 次** → 同一任務直接升 `sonnet`，不給 haiku 第二次機會。
- **sonnet 同一子任務連錯 2 次** → 帶著**完整失敗軌跡**升 `opus`：
  原始 prompt、兩次的輸出、每次錯在哪。不要讓 opus 從零重新踩同樣的坑。
- **opus 也失敗** → 停下來，把失敗軌跡整理給使用者，問要不要用 `fable` 或換方向。
- **降級**：opus/sonnet 解出一個模式後（例如「這類錯誤都是改 X 處」），
  把模式寫成明確步驟，降回 `haiku` 批次套用到其餘案例。
- **重試上限**：同一件事（含升級）最多兩輪。兩輪後必停，向使用者報告，
  不存在「再試一次就好」。判斷「同一件事」的標準：驗收條件相同。

## 6. 驗證不自驗

做的人不驗自己的產出。驗收一律派 **fresh-context** 的 agent
（新的 Agent 呼叫；不要用 SendMessage 續用做事的那個 agent——它會傾向為自己辯護）：

- **檔案落地**：驗收 agent 用 Read 讀回檔案，確認存在、完整、符合驗收條件。
- **程式碼**：驗收 agent 跑測試或實跑，貼回實際輸出。沒有輸出證據不算通過。
- **高風險判斷**（架構選擇、對外發送的內容、金融結論）：加第二意見——
  用不同 model 再判一次；或產 3 個候選答案，派一個 agent 當評審選優並說明理由。
- 驗收 agent 的 prompt 裡**不要透露**「這是誰做的」「做了幾次才成功」，
  避免錨定。只給：產出物、驗收條件、回報格式。
