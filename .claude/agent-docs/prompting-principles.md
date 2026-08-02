# Prompt 設計原則（跨模型）

> 依據 2026-08-01 研究的現役前緣模型 prompting guide 交叉結論：
> `~/.claude/opus5-prompting-guide.md`、`gpt-5.6-prompting-guide.md`、
> `GPT-5.6_Prompting_Guide_Research.md`、`glm-5.2-prompting-guide.md`、
> `prompting-guide-comparison.md`。
> 可信度：四份 guide 均為官方或官方來源整理，交叉一致；模型規格（context、effort
> 參數）為「非常確定」，官方自評的效能增益數字為「確定」（屬官方實測，非第三方複核）。
> 三模型共通趨勢：**從早期「加手寫警示（ALWAYS check／if X then Y）」轉向「模型原生
> 能力自動執行」——使用者要定義的是終點狀態與邊界條件，不是逐步過程。**

適用對象：本 harness 內所有 prompt 的撰寫（CLAUDE.md、agent-docs、派工模板、
subagent prompt）。模型無關——Claude／OpenAI／GLM 系前緣模型都適用。

## 原則 1：Effort 是旋鈕，不是救場

- Effort／reasoning 是**一等參數**，不是選配：Claude `effort`（low→max）、
  OpenAI `reasoning_effort`（＋`text.verbosity` 控制輸出長度）、GLM `reasoning_effort`。
- 需要更深的思考 → **先調 effort**（比升 model 便宜），effort 已到頂才升級 model。
  見 `model-dispatch.md` §3／§5。
- 不要用 prompt 寫「think harder」代替 effort 參數。

## 原則 2：Outcome-first（定義終點，不指揮過程）

- 描述「完成長什麼樣」＋成功條件＋停止條件，讓模型自己選最有效率的路徑。
- 避免逐步指令、過度規定工具調用順序、大量「ALWAYS／NEVER／must／only」。
- 絕對詞只留給真正的 invariant（安全、驗證、權限邊界）。

## 原則 3：精簡 prompt（刪冗餘、避矛盾）

- 刪：重複規則、不影響行為的風格指令、無效範例。
- 留：使用者可見結果、成功／停止條件、安全／業務／證據／權限約束、輸出格式要求。
- 檢查矛盾指令——互相衝突的規則比「資訊不足」更會造成不穩定。
- 官方實測（GPT-5.6）：精簡 system prompt 使分數 +10–15%、tokens −41–66%、成本 −33–67%。

## 原則 4：停止條件（重試上限、證據門檻、換路時機）

- 每個任務定義：什麼情況該停手回報，而不是繼續硬撐。
- 同輸入同方法只會同輸出——錯誤訊息與上次完全相同時是「換路」訊號，不是重試。
- 重試上限：同一驗收條件最多兩輪，兩輪後必停並向使用者報告。

## 原則 5：自主邊界集中寫一次

- 把「哪些動作不需問、哪些必須確認」集中成一處（本 harness 在 CLAUDE.md「動手邊界」
  與 `judgment-rubrics.md` R3），不要在多處重複抄寫。
- 避免重複「ask first」字眼——會造成不必要的審批停頓。

## 原則 6：代價意識

- 品質／成本用**工程層級**控制（effort 分級、model 分級），不是靠 magic prompt。
- 例行／高流量工作維持低 effort／低階 model；只在有 eval 證據證明增益時才升。

## 原則 7：驗證閉環

- 改完跑最相關的驗證：targeted tests → type-check／lint → build → 最小 smoke test。
- 驗證跑不了就說明原因並給次佳檢查，不默默跳過。
- 視覺／前端產物要先 render 再檢查 layout、clipping、缺漏內容。

## 對應本 harness

- `model-dispatch.md` §3／§5：effort-first、tier-second（原則 1）。
- `delegation-templates.md`：四件套含停止條件（原則 2／4）；各模板內建驗證與回報合約（原則 7）。
- `judgment-rubrics.md` R3：自主邊界（原則 5）；R4：換路訊號（原則 4）。
- CLAUDE.md「動手邊界」＋hooks：範圍與權限的架構式控管（原則 5／6）。
