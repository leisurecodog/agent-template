# agent-feats

備份與同步外部技能、外掛、harness 教學 repo 的目錄。

> 本目錄是**配方**：要啟用時把 `.claude/agent-feats/` 整個複製到 `~/.claude/agent-feats/`
> （並可另設 cron，見下方），`clones/` 由腳本管理、不進 repo。

## 內容

- `sources.md`：要同步的 GitHub repo 清單（每行一個 URL）。
- `sync_repos.sh`：同步腳本。讀 `sources.md`，對每個 repo：
  - 目錄不存在 → `git clone`。
  - 目錄已存在 → `git pull --ff-only`。
  - 目標目錄命名為 `clones/{owner}-{repo}`，避免同名 repo 衝突
    （例如 `mattpocock/skills` 與 `anthropics/skills`）。
  - 任一 repo 失敗會累計錯誤數，最後以非零 exit code 結束，不靜默吞錯。
- `clones/`：clone 出來的 repo（不手動編輯，由腳本管理）。

## Cron 排程

每晚 03:00 自動執行 `sync_repos.sh`，日誌寫入 `sync.log`。

**任何 session 開始處理本目錄工作前，先檢查 cron 是否已設定**：
`crontab -l` 看有沒有含 `sync_repos.sh` 的排程。若沒有就設定：

```bash
(crontab -l 2>/dev/null; echo "0 3 * * * ${HOME}/.claude/agent-feats/sync_repos.sh >> ${HOME}/.claude/agent-feats/sync.log 2>&1") | crontab -
```

路徑一律用 `${HOME}` 展開，不寫死絕對路徑。設定後用 `crontab -l` 確認存在。

## 手動操作

```bash
${HOME}/.claude/agent-feats/sync_repos.sh   # 立即同步全部 repo
```
