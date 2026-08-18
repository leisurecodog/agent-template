# Project Learnings

> 樣板見 `.claude/agent-docs/templates/lessons-template.md`。每條一行 `- [YYYY-MM-DD] 描述`（含情境要點；Mistakes 條必含怎麼避免再犯），依性質歸到對應 section。Consolidated Principles 由 consolidation runs 時綜合，平常教訓先寫進前四類。

## Patterns That Work

- [2026-08-02] prompt 設計依現役前緣模型 guide 原則（effort-first、outcome-first、精簡、停止條件）：三模型共通趨勢是「定義終點與邊界、信任模型選路徑」，不是加手寫警示。已落實於 `prompting-principles.md`＋`model-dispatch.md`＋`delegation-templates.md`。

## Mistakes to Avoid

- [2026-08-02] 編輯 `.claude/rules/hardware-arch.md` / `hardware-arch-template.md` 手動搬移 section 順序時，容易只換內容不換編號（例如某次 commit 只調換「設計原因」與「Block Diagram」的內容順序，卻留下 `2.6` 排在 `2.5` 前的倒序、以及 `## 2.` 重複掛在兩節上），且兩檔（規則＋範本）順序長期不同步。改完後務必用 `grep -n '^## ' <file>` 核對兩檔標題編號完全一致、無重複、無倒序，再回報完成。
- [2026-08-19] `LANG=zh_CN.UTF-8` 下 bash 把「`$VAR` 後緊跟的全形字」（`（`、`。` 等 U+0080+）併入變數名，`$TARGET（某` 被解析成變數 `TARGET（` → runtime 報 `unbound variable`（`bash -n` 抓不到，只在執行期爆）。在本 repo 的 scaffold.sh 與 claude-self-learn.sh 各修了實碼中的 4 處（另 2 處在註解內無害）。**避免再犯：寫 bash script 時，凡 `$var` 後緊接非 ASCII 字元一律用 `${var}` 括住；完工後以 `perl -ne 'while(/\$([A-Za-z_]\w*)([\x80-\xff])/g){print "$ARGV:$.: \$$1\n"}' *.sh` 掃一遍驗證（注意 perl 掃多檔時 `$.` 不歸零，單檔掃才準）。

## Domain Knowledge

- [2026-08-02] `git push` 在此 repo 會被 `.claude/hooks/claude-guard.sh`（PreToolUse:Bash）擋下，錯誤訊息「git push blocked: run it manually to confirm」；commit 仍可正常執行。遇到此錯誤不要重試 push，改為請使用者手動執行或明確授權。

## Open Questions

## Consolidated Principles
