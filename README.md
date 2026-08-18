# agent-template

Claude Code 的專案起始模板：一套精簡、領域中立的工程紀律 harness，工作與私人專案通用。
新專案以此為骨架，再依專案需求增刪。

## 內含

- `CLAUDE.md` — 專案版核心指示（誠實＋來源、先計畫、驗證才說完成、動手邊界、安全底線）
- `.claude/agent-docs/` — 判斷力 rubric、模型調度、程式規範、派工模板、prompt 設計原則、制度維護協議（需要時才 Read）
- `.claude/rules/` — 路徑限定的語言規則（`python.md`、`c++.md`，讀到對應檔案才載入）
- `.claude/hooks/` + `.claude/settings.json` — 自動 format／lint／secrets/push guard（工具沒裝就靜默跳過）
- `.claude/commands/` — `update-lessons`、`consolidation-lessons`
- `scaffold.sh` / `check.sh` — 複製成新專案骨架；模板自檢（語法＋shellcheck）
- `.claude/agent-feats/` — skill 來源 repo 的同步配方（`sources.md` + `sync_repos.sh`，見下）
- `tasks/` — 跨 session 狀態：`lessons.md`（另可加 `todo.md`、`progress.md`）
- `docs/plugins.md` — 推薦 plugin 清單

## Skills：從 clones 挑選與推薦

Skill 本體**不進模板**（全域已載入，複製會漂移）。skill 來源 repo 由
[`agent-feats`](.claude/agent-feats/CLAUDE.md) 機制同步到
`~/.claude/agent-feats/clones/`，並以 symlink 掛到 `~/.claude/skills/`（自動載入）。

新機器恢復基礎設施：把 `.claude/agent-feats/` 複製到 `~/.claude/agent-feats/`，跑
`sync_repos.sh`，再依其 CLAUDE.md 設 cron 與建 symlink。

從 clones 挑選/推薦的通用 skill（工作＋私人皆適用）：

**工程紀律**
- mattpocock-skills（engineering）：tdd、diagnosing-bugs、code-review、codebase-design、domain-modeling、implement、research、resolving-merge-conflicts、wayfinder、to-spec、to-tickets、triage
- obra-superpowers：systematic-debugging、receiving-code-review、writing-plans、executing-plans、using-git-worktrees、verification-before-completion、finishing-a-development-branch、subagent-driven-development

**研究／思考**
- deep-research（affaan-m-ecc）、grilling、handoff、writing-great-skills、teach（mattpocock-skills）
- harness-creator（walkinglabs-learn-harness-engineering）

**文件／產物**
- docx、pdf、pptx、xlsx、theme-factory、frontend-design、web-artifacts-builder、webapp-testing、canvas-design、brand-guidelines、slack-gif-creator、algorithmic-art（anthropics-skills）
- claude-api、mcp-builder、skill-creator、doc-coauthoring、internal-comms（anthropics-skills）

**領域特定**（股票研究、寫作等）屬個人域，留在 `~/.claude/skills/`，不進模板。

專案若要凍結特定 skill 版本：複製成真實目錄到 `.claude/skills/<name>/`
（會與全域漂移，只在必要時做）。

本節是精選推薦；完整 repo 清單與分類以 `sources.md` 為準，兩處衝突時以 `sources.md` 為準。

## 快速開始

1. `git clone` 本目錄；要自動化骨架安裝，跑 `./scaffold.sh <新專案目錄>`。
2. 依專案調整 `CLAUDE.md`（刪多餘規則、加專案特有路由）；非硬體專案刪掉
   `.claude/rules/hardware-*.md`。
3. 確認 hooks 工具依賴（ruff、shellcheck、clang-format、cppcheck）已安裝；跑 `./check.sh` 自檢。
4. 新 session 開始照 `CLAUDE.md` 的規則運作，教訓寫進 `tasks/lessons.md`。
