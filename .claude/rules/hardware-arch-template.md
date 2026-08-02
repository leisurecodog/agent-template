---
title: {MODEL_NAME} Functional Model
status: Draft
date: {YYYY-MM-DD}
---

# {MODEL_NAME} TLM Functional Model 文件

> 依 `~/.claude/rules/hardware-arch.md`。**functional behavioral model 為主**，不寫 RTL
> （pipeline/clock/power 不適用；register 為 software 可見面）。
> Section 順序＝讀者閱讀順序：Overview → 設計原因 → 時序 → Interface → Register →
> Config/Result → 行為細節。

## 1. Scope

一句話：這是 **[模組/feature 名稱]** 的 functional model，涵蓋 **[交易類型/行為]**，明確排除
**[非本文件範圍]**。

## 2. Overview

2–3 句：此 model 提供什麼 transaction 服務、用途（golden reference／BFM／stub）、放系統哪個位置。

```mermaid
block-beta
  columns 3
  block init["Initiator (Test/Scoreboard)"] end
  func["本 Model"]
  func --> init
  init --> func
```

## 2.5 Block Diagram（內部結構分解）

展示 model 內部組成分解（sub-block／主要模組間如何連接）。單一模塊可標核心 storage／介面／邏輯。

```mermaid
block-beta
  columns 3
  io_in["I/O / socket 輸入"]
  block core["核心 logic"]
    cols 1
    b1["datapath"]
    b2["state / mem"]
  end
  io_out["輸出 socket"]
  io_in --> core
  core --> io_out
```

## 3. 設計原因（Why / Design Rationale）

為什麼是 functional model、為什麼用這個行為方式、取捨：
- 【要達成的目的：例如當 golden reference、省 simulation 時間、可執行 spec】
- 【與真硬體/其他實作的取捨：如不做 timing 以換純行為正確、簡化後會失去什麼】
- 【若未來可能改為什麼（已知限制）】

## 4. 時序圖（Transaction Sequence Diagram）

關鍵交易的 initiator↔model 交互走查（LT／AT）。

```mermaid
sequenceDiagram
  participant SW as Software/Test
  participant M as {MODEL}
  SW->>M: b_transport(WRITE, addr, data)
  M-->>SW: TLM_OK_RESPONSE
  SW->>M: b_transport(READ, addr)
  M-->>SW: ok(TLM_OK_RESPONSE, data=...)
```

## 5. Interface

**I/O 資料介面（model 代表的硬體介面）：**
| 名稱 | 方向 | 型別/寬度 | Clock 域 | 說明 |
|------|------|-----------|----------|------|
| 【ex. i_data】 | input | uint32 | core | 【】|

**TLM 交易介面（LT/AT、socket、交易方向）：**
- 交易型態：LT（`b_transport()`）／ AT（`nb_transport_fw/bw()`）／ 純
- Socket／port／transaction 方向與負載
- AT 用 `peq_with_cb_and_phase`、payload pooling（`tlm_mm_interface`）(如用)
- 介面接受/發出哪些 transaction、回傳什麼：**此為行為合約**

## 6. Register Map（software 存取的 register 建模；無則拼「—」）

| Field | Offset | R/W | 存取副作用（行為） | Reset | 說明 |
|-------|--------|-----|--------------------|-------|------|
| 【ex. CTRL.enable】 | 0x0 | W | 寫 1 啟動 model | 0 | 【】 |

> functional model 常需模仿真硬體 register，供 software 驅動並與硬體比對。

## 7. Config / Setting Example and Result

如何設定 model（register 寫入／參數），以及設完後的預期結果。**讓讀者可直接照做、照驗**。

```text
Setting:
  1. 寫 CTRL.enable = 1         // 啟動
  2. 寫 CFG.mode = 2            // 切模式
Expected result:
  - 讀 STAT.ready == 1
  - 後續 WRITE 成功回 OK
  - 越界 WRITE 回 error 且不改狀態
```

## 8. Functional Data Model

**交易型別（transaction / data object）：**
| 欄位 | 型別 | 寬度/範圍 | 說明 |
|------|------|-----------|------|
| 【transaction 欄位...】 | | | |

**Functional State（model 內部語意狀態）：**
| State | 型別 | 說明 |
|-------|------|------|
| 【ex. buffer、mode、counter】 | | |

## 9. Behavioral Semantics

對每個 incoming transaction 描述「輸入 → 狀態變化 → 輸出」。以條列或偽碼寫。

```text
on <transaction T>:
    if T.op == WRITE:
        state.buf[n] = T.data
        state.count = state.count + 1
        respond OK
    elif T.op == READ:
        respond OK(data = state.buf[head])
        state.head = (head + 1) ...
    # boundary / error cases
```

(無明顯狀態機則行為偽碼即達標；有狀態機可另附：)
```mermaid
stateDiagram-v2
  [*] --> IDLE
  IDLE --> BUSY : start
  BUSY --> DONE : complete
```

## 10. Timing Model

- 近似 latency / `delay` 基準：**【如已知】** ／ 不建模時間（pure-functional）
- AT phase 序列（若 AT）：`BEGIN_REQ → ... → END_REQ`

## 11. Concurrency / 同步

- 【thread 喚醒與同步：event／mutex／queue】 ／ 單執行緒順序

## 12. Assumptions / Deviations

- 對真硬體的簡化 / 假設：**【至少一條，不空白】**
- TBD（期限：{YYYY-MM-DD}）：

---

# 完整範例（對照填：APB 目標之 TLM functional model）

> 展示 TLM functional 文件的 reader-friendly 密度。照「Overview→設計→時序→Interface→
> Register→Config/Result→細節」順序，重點是讓讀者先懂能做什麼、再懂怎麼用。

```markdown
---
title: apb_target_model Functional Model
status: Draft
date: 2026-08-02
---

# apb_target_model 文件

## 1. Scope
「apb_target_model」是一個 **APB slave 的 TLM functional model**，提供 **LT read/write
交易服務**，做為 software 的 golden reference；明確排除 **AT 交易、錯誤回復、power 建模**。

## 2. Overview
CPU/tb 以 LT 對本 model 寫資料與讀回。model 以 32-word 記憶體為 functional state，做為
golden 期望值來源。**不建模週期時間**（pure-functional），求快、可當 executable spec。

block diagram（內部）：
```mermaid
block-beta
  columns 3
  socket_in["APB target socket"]
  block core["model core"]
    cols 1
    ctrl["write/read 控制"]
    mem["mem[31:0][7:0]"]
  end
  irq["o_irq"]
  socket_in --> ctrl
  ctrl <--> mem
  ctrl --> irq
```

## 3. 設計原因
- 目的：software 的 golden reference，驗證時拿 model 期望值比對 RTL。
- 取捨：捨 timing 換純行為、可重用於多場景；**若改用有 delay 才需描述 latency**。
## 4. 時序圖（transaction 走查）

sequenceDiagram
  participant SW as Software/Test
  participant M as apb_target_model
  SW->>M: b_transport(WRITE, 0x8, 0xA5)
  M->>SW: TLM_OK_RESPONSE
  SW->>M: b_transport(READ, 0x8)
  M->>SW: ok(data=0xA5)
```

## 5. Interface
**I/O 資料介面：**
| 名稱 | 方向 | 型別/寬度 | Clock 域 | 說明 |
|------|------|-----------|----------|------|
| i_pclk | input | 1 | pclk | APB clock |
| i_paddr | input | uint32 | pclk | APB 位址 |
| i_pwdata | input | uint32 | pclk | APB 寫資料 |
| o_prdata | output | uint32 | pclk | APB 讀資料 |
| o_irq   | output | 1      | pclk | 中斷輸出 |

**TLM socket：**
- 單一 target socket，LT；接受 WRITE/READ。
- 回傳 `TLM_OK_RESPONSE`／越界 `TLM_ADDRESS_ERROR_RESPONSE`。

## 6. Register Map
| register | Offset | R/W | Access 副效用 | Reset | 說明 |
|----------|--------|-----|--------------|-------|------|
| CTRL.enable | 0x0 | W | 寫 1 清空並啟動 | 0 | 主使能 |
| CFG.freq    | 0x4 | RW | 記住後用於分頻 | 0 | 取捨用配置 |
| DATA | 0x8 | W | 寫入 mem[word(addr)] | — | 資料寫入點 |
| irq_status  | 0x10 | RO | 讀回後清 0 | 0 | 中斷狀態（可讀比對）|

## 7. Config / Setting Example & Result
```text
Setting:
  寫 CTRL.enable = 1 → 清空并進入 ready
  寫 CFG.freq = 1    → 啟用除頻
  寫 DATA = 0xA5 @0x8 → 存 mem[1]=0xA5, 回 OK
Expected result:
  讀 DATA @0x8 → 0xA5（golden 比對）
  讀 irq_status → 恰好反映中斷（回比對 *)
```

## 8. Functional Data Model
| 欄位 | 型別 | 寬度 | 說明 |
|------|------|------|------|
| address | sc_uint | 32 | 位址 |
| data_ptr | uint8* | 32 | 讀寫資料 |
| command | WRITE/READ | 1 | R/W |
| len | sc_uint | 32 | 長度(bytes) |

State：`mem[31:0][7:0]` (uint8) 目標內容、`cfg.freq`。

## 9. Behavior
```
on WRITE:
  if addr >= 4*31 → response = TLM_ADDRESS_ERROR_RESPONSE
  else: mem[word(addr)] = data; response = OK
on READ:
  if addr >= 4*31 → ADDRESS_ERROR
  else: data = mem[word(addr)]; response = OK
```
（本例無 FSM。）

## 10. Timing Model
不建模時間；delay=0（pure-functional）。

## 11. Concurrency
單執行緒順序執行；無 event/mutex 目前。

## 12. Assumptions / Deviations
- 簡化：不做 write 延遲、不做 power/clock domain。
- 未知（到 2026-08-10 定奪）：多 master 同時寫的 atomicity。
```

> 填寫提醒：讀者先看 Overview→設計原因→時序圖→Interface→Register→Config 就能【懂】,
> Behavior 是讓驗證者可查的細節。