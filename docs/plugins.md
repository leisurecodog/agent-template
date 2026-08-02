# 推薦 Plugin 清單

Plugin 是機器全域安裝（cache 在 `~/.claude/plugins/`），**不進模板**。這裡列出通用工程相關的
推薦 plugin 與安裝指令，供新專案／新機器按需安裝。

```bash
claude plugin install claude-code-setup@claude-plugins-official   # 必裝
claude plugin install ponytail@ponytail        # YAGNI／最小可行紀律
claude plugin install drawio@365-skills        # drawio 架構圖
claude plugin install clangd-lsp@claude-plugins-official   # C/C++ LSP
claude plugin install pyright-lsp@claude-plugins-official   # Python LSP
claude plugin install health@claude-health             # 健康檢查
```

| Plugin | Marketplace | 用途 |
|---|---|---|
| **claude-code-setup** | claude-plugins-official | **必裝**：分析 codebase 並推薦對應的 hooks、skills、MCP servers、subagents。新專案骨架建好後先跑它，讓自動化設定跟上專案 |
| ponytail | ponytail | 最小可行、YAGNI，管「寫多少」 |
| drawio | 365-skills | drawio 架構圖產出 |
| clangd-lsp | claude-plugins-official | C/C++ 語言伺服器 |
| pyright-lsp | claude-plugins-official | Python 語言伺服器 |
| health | claude-health | Claude Code 環境健康檢查 |
| gemini | gemini-search | Google 搜尋（網路查證用） |

先註冊 marketplace（`claude plugin marketplace add <repo>`）再 install；確切指令以
`claude plugin --help` 為準。
