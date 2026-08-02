---
paths:
  - "**/*.arch.md"
  - "**/arch/**"
  - "**/*.spec.md"
  - "**/hardware/*.md"
---
# TLM Functional Model 架構文件規則（模組級／單一 feature）

用途：撰寫**單一模組或單一 feature 的 TLM（Transaction-Level Modeling）behavior／functional
model 規格**——描述這個 model **在交易層級的行為語意**，供 SystemC/C++ 實作 functional model
（reference model、BFM、或 golden model）前設計與 review。
有別於 RTL 架構文件：**不寫 pipeline 延遲、synthesis、clock/power、register map**。
FSM 可無——functional model 以**行為**為主，狀態機只是其一表述方式。

## 定位（寫每份文件前先答）

- 讀者是誰：SystemC model 實作者、functional 驗證者、後續維護者、審查者？
- 範圍：單一模組、單一 feature、還是 feature 內多個 transaction 行為？
- 目的：定**行為合約**（輸入→輸出語意）、定 transaction 介面、記錄取捨、還是給 review？

**一句話寫進開頭「Scope」段**。範圍不清楚就不開寫。

## Data Model（先界定資料型別，再行行為）

Functional model 的**核心**是資料型別與狀態，不是介面腳位。寫文件前先把「模型視為
partition 哪些資料」定清楚：
- Data objects：transaction／packet／處理單位的欄位（不是 signal，是結構化資料型別）。
- State：model 內部的 functional state（buffers、計數、模式、context）——不是 RTL register，
  是有語意資料。

## 文件結構（照此 section 順序）

1. **Scope** — 一句話：這是什麼、涵蓋哪些交易類型／行為、明確排除什麼（ex.「僅 master、不做
   錯誤回復」、「不含 power」）。
2. **Overview** — 2–3 句這個 model 提供什麼 transaction 服務、用在 golden ref／BFM／stub 哪一途，
   放系統哪個位置。附**行為層級 block diagram**。
3. **Functional Data Model** — 定義所有 transaction/data 型別與欄位、model 的 functional state
   結構（見上）。**此段優先寫**，行為皆由它推導。
4. **Interface** — 描述這個 model 代表的硬體介面（**兩層都要**，缺一不算完整）：
   - **I/O 資料介面**：外部 I/O、資料路徑接口——即使是 functional model，也需描述它模擬的
     硬體介面長相（名稱、方向、資料型別/寬度、clock 域），讓讀者知道 model 對應哪個硬體介面、
     如何接進 testbench。用表格，不用寫 signal 腳本細節。
   - **TLM 交易介面**：`b_transport`（LT）／`nb_transport_fw/bw`（AT）、ports／sockets、
     `peq with cb and phase`／`tlm_mm_interface`（payload pooling）用法。寫「介面接受/發出哪些
     transaction、回傳什麼」。
5. **Behavioral Semantics** — **functional model 的主體**：對每個 incoming transaction，
   model 做規則、狀態如何變、outgoing transaction 長怎樣。用條列或偽碼（pseudo-code）寫，
   不寫 RTL。
   - 可選以 FSM 表述（`stateDiagram-v2`）——但有寫偽碼行為描述即達標。
6. **Register Map** — **software 透過 bus 存取的 register 建模**：offset、field、bit、R/W、
    access side-effect。（註：functional model 常需 model 真硬體的 register，供 software 驅動
    並與真硬體比對。）沒 register 就打「—」。
7. **Timing Model（適用時）** — functional model 的近似時序語意：每筆 transaction 的近似
   latency、`delay` 參數、AT phase 序列（`BEGIN_/END_`）。若為 pure-functional 不帶時間，
   明寫「不建模時間」。
8. **Concurrency / 同步** — thread 如何喚醒與同步、event、mutex、queue 的並行行為。
9. **Assumptions / Deviations** — functional model vs 真硬體可能存在的簡化、假設、偏差，與
   誤用後果。務實列出，不隱藏。

## 寫作紀律

- **行為可被比對**：Behavioral Semantics 段要精確到能讓驗證者直接對 golden reference 做
  output 比對，或用 property 檢查。
- **functional 優先、非硬體實作**：描述「輸入交易→模型狀態→輸出交易」的語意，不描述
  clock 週期、gate、synthesis、pipeline。FSM 只在表達行為方便時使用，非必須。
- **務實不虛**：functional state 與 transaction 行為是**事實**，要能對得上實作的
  SystemC/C++ model。寫不清處標 TBD＋時限，不用模糊字帶過。
- **不連寫 model 程式碼**：這是行為文件，寫到 model 前 review 的層級即可。

## 產出格式規範

- Markdown 為主。
- 圖用 Mermaid：`flowchart`（資料流）、`sequenceDiagram`（transaction 交互）、`stateDiagram-v2`
  （有 FSM 時）、`block-beta`（block 層級）。
- 交易交互：`sequenceDiagram` 呈現 initiator↔target 的 AT/LT 呼叫與回傳。
- 檔名 `{name}_func.md`／`{name}_arch.md`，放 `docs/` 或 model 目錄，並在 `docs/README.md`
  建索引。
- 完整範例見 `hardware-arch-template.md`。

## 驗收（寫完自檢，缺一不交）

- 已答定位、寫進 Scope。
- Functional Data Model 段定義了 transaction 型別與 functional state（不是 signal port list）。
- Interface 段**兩層都有**：I/O 資料介面（方向/型別/clock 域）＋TLM 交易介面（LT/AT/socket）。
- Behavioral Semantics 段對每個 transaction 定義「輸入→狀態變化→輸出」，至少偽碼或清楚條列。
- Register Map 段列出 software 可存取的 register（offset/field/RW/副作用）；無則明寫「—」。
- 提及 timing 是「近似」還是「不建模時間」，沒有含糊。
- Concurrency 段說明同步機制（無並行則明說「單執行緒順序」）。
- Assumptions／Deviations 段​列出 model 與真硬件的差異與簡化，**不空白**。
- 文件符合「functional behavioral model、非 RTL」的界線。