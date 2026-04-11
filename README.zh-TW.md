# 🐍 Venom

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Works with Claude Code](https://img.shields.io/badge/works%20with-Claude%20Code-8A4FFF)](https://code.claude.com)
[![한국어](https://img.shields.io/badge/lang-한국어-red.svg)](README.md)
[![English](https://img.shields.io/badge/lang-English-blue.svg)](README.en.md)
[![简体中文](https://img.shields.io/badge/lang-简体中文-green.svg)](README.zh-CN.md)

> **為 Claude Code 打造的通用工作準則，5秒注入任何專案**

Venom 是一套 **即插即用（drop-in）工作準則**，讓 Claude Code 在所有開發專案中
保持一致的安全性、一致的驗證流程和一致的自我糾錯能力。複製兩個檔案，執行一次
`/venom`，專案即刻武裝完畢。

名字來源於 **「注入毒液以進化」** 的概念。Venom 不僅是一套規則集合，更是一個
滲透專案後將自身*蛻變（metamorphose）*以適配專案的**活體共生體（living
symbiote）**——在工作中持續學習、持續進化。

---

## ✨ Venom 能做什麼

- 🛡️ **確定性安全防護** —— `rm -rf /`、`git push --force`、`.env` 洩露、
  手動編輯 lockfile 等事故被 hook 100% 攔截。CLAUDE.md 是建議，hook 是強制。
- 🧠 **自我糾錯記憶** —— Claude 犯的錯誤、被拒絕的操作（`PermissionDenied`）、
  因 API 錯誤結束的輪次（`StopFailure`）會自動記錄到
  `.claude/memory/mistakes.md`，並在下次會話開始時重新注入上下文。
  *同樣的錯誤絕不犯第二次。*
- 💰 **Token 節省** —— 工具鏈本身就為降低 token 成本而設計。SessionStart
  注入會過濾佔位符/格式範例，只注入最近 N 條記錄。被拒絕的工具呼叫會被學習，
  下次會話不再重試。驗證門控提前阻止無意義的重試。*工具鏈是節省，不是成本。*
- 🧬 **按專案進化** —— 一行 `/venom` 即可讓 Venom 深度分析專案的領域模型、
  架構模式和開發模式，將 rules·skills·hooks *進化*為適配該專案的版本。
  變更前自動備份到 `.claude/.venom-backup/`。
- 🫀 **活體自我進化** —— `/venom` 之後 Venom 依然活著。
  同一錯誤出現2次 → 自動強化規則/hook，同一模式出現3次 → 自動提取 skill，
  每次會話開始時提示需要進化的領域，每次會話結束時偵測進化機會。
- 🌐 **語言無關** —— Python、JS/TS、Go、Rust、Java、Ruby、PHP……
  任何語言都能運作。語言偵測在執行時發生，未安裝則靜默跳過。
- 📦 **即插即用** —— 只需將 `CLAUDE.md` 和 `.claude/` 兩個檔案複製到專案根目錄。
  無相依性、無安裝腳本、無背景程序。

---

## 🚀 快速開始

### 推薦：npm CLI 一行指令

```bash
cd /path/to/your-project
npx @cgyou/venom-init
```

此指令將：

1. 在目前目錄安裝 `CLAUDE.md` 和 `.claude/`。
2. 如已存在，先自動備份到 `.venom-backup/<timestamp>/` 再覆蓋。
3. `.claude/settings.local.json`（使用者本地權限開關）**始終保留**。
4. 自動為 hook 腳本設定執行權限，並將 `.venom-backup/` 加入 `.gitignore`。

選項：

```bash
npx @cgyou/venom-init --dry-run        # 只輸出計畫，不做更改
npx @cgyou/venom-init --from-git       # 從 GitHub main 直接拉取而非使用內建副本
npx @cgyou/venom-init --from-git --ref some-branch
npx @cgyou/venom-init --no-backup --force   # 不備份直接覆蓋（危險）
```

安裝後在 Claude Code 會話中執行一次：

```
/venom            # 完全吸收專案 —— 領域·架構·模式深度分析後全面進化
```

### 手動：git clone

如果不想使用 CLI，仍可手動操作：

```bash
git clone https://github.com/KirSsuRyu/venom.git
cp -r venom/CLAUDE.md venom/.claude /path/to/your-project/
chmod +x /path/to/your-project/.claude/hooks/*.sh
```

完成。從此刻起，該專案中的 Claude Code：

- 絕對無法執行危險指令，
- 絕對無法讀寫秘密檔案，
- 編輯後自動格式化·驗證，
- 犯錯時當場記錄到記憶中，
- 下次會話帶著那些錯誤的上下文啟動。

---

## 📦 包含什麼

```
your-project/
├── CLAUDE.md                    # Claude Code 每次會話自動載入的頂層準則
└── .claude/
    ├── README.md                # .claude/ 資料夾內部指南
    ├── settings.json            # 權限·hook 註冊·環境變數
    ├── commands/
    │   └── venom.md             # /venom 斜線命令
    ├── rules/                   # 自動載入的 7 個領域規則 (00-55)
    ├── skills/                  # 6 個通用技能 (review/debug/test/git/memory/evolve)
    ├── hooks/                   # 10 個確定性強制腳本
    └── memory/                  # 專案永久記憶 (mistakes/lessons/decisions)
```

詳細結構和各檔案角色請參考 [`.claude/README.md`](.claude/README.md)。

---

## 🧪 攔截/自動化一覽

| 攔截項目 | 位置 |
|---|---|
| `rm -rf /` `~` `*` `.`、`mkfs`、`dd`、fork bomb、`sudo`、`chmod -R 777`、`curl\|sh` | `block-dangerous.sh` |
| `git push --force`、`reset --hard`、`clean -fd`、`--no-verify` | `block-dangerous.sh` + `settings.json` |
| `.env`、`id_rsa`、`~/.ssh/*`、`~/.aws/credentials` 讀/寫 | `protect-paths.sh` + `settings.json` |
| `/etc`、`/usr`、`.git/`、`node_modules/`、`dist/` 寫入 | `protect-paths.sh` |
| 手動編輯 lockfile（`package-lock.json`、`Cargo.lock`、…） | `protect-paths.sh` |

| 自動行為 | 位置 |
|---|---|
| 會話開始時注入歷史錯誤/教訓 + 進化狀態 | `session-start.sh` |
| 每次提示時注入 git 分支/dirty 狀態 | `inject-context.sh` |
| 檔案編輯後按語言自動執行格式化器 | `auto-format.sh` |
| 工具失敗時自動記錄到 mistakes.md | `record-mistake.sh` |
| 未驗證就嘗試結束時阻止 | `verify-before-stop.sh` |
| 偵測重複錯誤 → 建議進化 | `trigger-evolution.sh` |

---

## 🧬 `/venom` —— 完全吸收專案

一次 `/venom` 即可讓 Venom 完全滲透專案：

- **領域深度分析** —— 架構模式、領域模型、開發模式目錄
- **10~15 個檔案程式碼取樣** —— 觀察風格、命名、錯誤處理慣例
- **產生專案定制 rules** —— `60-project.md`、`61-architecture.md`、
  `62-domain.md`、`63-patterns.md`
- **產生專案定制 skills** —— 建置、架構、領域指南等
- **進化現有 rules/skills/hooks** —— 替換為該專案的實際慣例
- **產生新 hooks** —— 架構保護、領域保護、品質強制等
- **播種自我進化機制** —— 此後每次會話自動學習和成長
- **變更前自動備份** —— 保存在 `.claude/.venom-backup/`

詳細流程請參考 [`.claude/commands/venom.md`](.claude/commands/venom.md)。

## 🫀 活體進化

`/venom` 執行之後 Venom 依然活著：

| 觸發條件 | 進化行為 |
|---|---|
| 同一錯誤出現 2 次 | 強化規則或自動產生 hook |
| 同一模式出現 3 次 | 自動提取為 skill |
| 使用者糾正 | 將慣例加入規則中 |
| 會話開始 | 自動提示需要進化的領域 |
| 會話結束 | 偵測重複錯誤 → 建議進化 |

詳細協議請參考 `.claude/rules/55-self-evolution.md`。

---

## 🤝 一起來建設

Venom 的願景是 **所有 Claude Code 使用者共同培育的公共工作環境**。
以下貢獻均受歡迎：

- 🐛 **Bug 回報** —— hook 誤觸發、錯誤攔截、遺漏的危險模式
- 💡 **新 hook/skill/rule 提案** —— 如果在其他專案驗證過，
  歡迎泛化後提交到本倉庫
- 🌍 **語言/技術堆疊覆蓋擴展** —— 為 `auto-format.sh` 新增格式化器，
  為 `test-runner` 新增測試執行器，為 `venom.md` 新增清單檔案識別
- 🧬 **按專案進化配方** —— 提交針對特定框架（Next.js、FastAPI、Spring、
  Rails 等）的專用進化配方
- 🌐 **翻譯** —— 目前提供韓語 + 英語 + 中文。歡迎其他語言翻譯
- 📚 **使用案例·回饋** —— 在 Discussions 中分享 Venom 在您專案中的表現。
  誤攔截的案例、成功攔截的事故，都很有價值

### 貢獻指南（簡版）

1. 請先開 issue。大變更先達成共識最快。
2. PR 要小，一個 PR 一個變更。
3. 新增 hook/skill/rule 時：
   - 在 README 或檔案開頭說明它做什麼、為什麼需要
   - 盡量在 PR 描述中附上冒煙測試指令
   - 如有語言/技術堆疊相依性請明確標註（Venom 的核心價值是 *語言無關*）
4. 對 CLAUDE.md 和 `.claude/rules/00-core.md` 的安全規則做*放鬆*的變更
   會非常保守地審查。*收緊*的變更則受歡迎。
5. 提交訊息推薦使用 conventional commits（`feat:`、`fix:`、`docs:`、…）。

### 行為準則

相互尊重，就事論事，歡迎新人。
詳情請參閱 [Contributor Covenant](https://www.contributor-covenant.org/)。

---

## 📜 授權條款

MIT。自由複製·修改·再散布。使用 Venom 建置的專案不繼承 Venom 的授權條款。

---

## 🙏 致謝

Venom 建構在 [Claude Code](https://code.claude.com) 的 hooks·skills·slash
commands 系統之上。感謝 Anthropic 的
[官方文件](https://code.claude.com/docs)、[Skill 撰寫最佳實踐](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
以及社群中所有的 hook 實驗。

---

> *「好的工具不會讓使用者變得更聰明。它讓使用者無法犯蠢。
> 而最好的工具，每天都在讓自己變得更聰明。」*
> —— Venom 的設計哲學
