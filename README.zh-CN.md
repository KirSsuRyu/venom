# 🐍 Venom

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Works with Claude Code](https://img.shields.io/badge/works%20with-Claude%20Code-8A4FFF)](https://code.claude.com)
[![한국어](https://img.shields.io/badge/lang-한국어-red.svg)](README.md)
[![English](https://img.shields.io/badge/lang-English-blue.svg)](README.en.md)
[![繁體中文](https://img.shields.io/badge/lang-繁體中文-orange.svg)](README.zh-TW.md)

> **为 Claude Code 打造的通用工作准则，5秒注入任何项目**

Venom 是一套 **即插即用（drop-in）工作准则**，让 Claude Code 在所有开发项目中
保持一致的安全性、一致的验证流程和一致的自我纠错能力。复制两个文件，运行一次
`/venom`，项目即刻武装完毕。

名字来源于 **"注入毒液以进化"** 的概念。Venom 不仅是一套规则集合，更是一个
渗透项目后将自身*蜕变（metamorphose）*以适配项目的**活体共生体（living
symbiote）**——在工作中持续学习、持续进化。

---

## ✨ Venom 能做什么

- 🛡️ **确定性安全防护** —— `rm -rf /`、`git push --force`、`.env` 泄露、
  手动编辑 lockfile 等事故被 hook 100% 拦截。CLAUDE.md 是建议，hook 是强制。
- 🧠 **自我纠错记忆** —— Claude 犯的错误、被拒绝的操作（`PermissionDenied`）、
  因 API 错误结束的轮次（`StopFailure`）会自动记录到
  `.claude/memory/mistakes.md`，并在下次会话开始时重新注入上下文。
  *同样的错误绝不犯第二次。*
- 💰 **Token 节省** —— 工具链本身就为降低 token 成本而设计。SessionStart
  注入会过滤占位符/格式示例，只注入最近 N 条记录。被拒绝的工具调用会被学习，
  下次会话不再重试。验证门控提前阻止无意义的重试。*工具链是节省，不是成本。*
- 🧬 **按项目进化** —— 一行 `/venom` 即可让 Venom 深度分析项目的领域模型、
  架构模式和开发模式，将 rules·skills·hooks *进化*为适配该项目的版本。
  变更前自动备份到 `.claude/.venom-backup/`。
- 🫀 **活体自我进化** —— `/venom` 之后 Venom 依然活着。
  同一错误出现2次 → 自动强化规则/hook，同一模式出现3次 → 自动提取 skill，
  每次会话开始时提示需要进化的领域，每次会话结束时检测进化机会。
- 🌐 **语言无关** —— Python、JS/TS、Go、Rust、Java、Ruby、PHP……
  任何语言都能工作。语言检测在运行时发生，未安装则静默跳过。
- 📦 **即插即用** —— 只需将 `CLAUDE.md` 和 `.claude/` 两个文件复制到项目根目录。
  无依赖、无安装脚本、无后台进程。

---

## 🚀 快速开始

### 推荐：npm CLI 一行命令

```bash
cd /path/to/your-project
npx @cgyou/venom-init
```

此命令将：

1. 在当前目录安装 `CLAUDE.md` 和 `.claude/`。
2. 如已存在，先自动备份到 `.venom-backup/<timestamp>/` 再覆盖。
3. `.claude/settings.local.json`（用户本地权限开关）**始终保留**。
4. 自动为 hook 脚本设置执行权限，并将 `.venom-backup/` 添加到 `.gitignore`。

选项：

```bash
npx @cgyou/venom-init --dry-run        # 只输出计划，不做更改
npx @cgyou/venom-init --from-git       # 从 GitHub main 直接拉取而非使用内置副本
npx @cgyou/venom-init --from-git --ref some-branch
npx @cgyou/venom-init --no-backup --force   # 不备份直接覆盖（危险）
```

安装后在 Claude Code 会话中运行一次：

```
/venom            # 完全吸收项目 —— 领域·架构·模式深度分析后全面进化
```

### 手动：git clone

如果不想使用 CLI，仍可手动操作：

```bash
git clone https://github.com/KirSsuRyu/venom.git
cp -r venom/CLAUDE.md venom/.claude /path/to/your-project/
chmod +x /path/to/your-project/.claude/hooks/*.sh
```

完成。从此刻起，该项目中的 Claude Code：

- 绝对无法执行危险命令，
- 绝对无法读写秘密文件，
- 编辑后自动格式化·验证，
- 犯错时当场记录到记忆中，
- 下次会话带着那些错误的上下文启动。

---

## 📦 包含什么

```
your-project/
├── CLAUDE.md                    # Claude Code 每次会话自动加载的顶层准则
└── .claude/
    ├── README.md                # .claude/ 文件夹内部指南
    ├── settings.json            # 权限·hook 注册·环境变量
    ├── commands/
    │   └── venom.md             # /venom 斜杠命令
    ├── rules/                   # 自动加载的 7 个领域规则 (00-55)
    ├── skills/                  # 6 个通用技能 (review/debug/test/git/memory/evolve)
    ├── hooks/                   # 10 个确定性强制脚本
    └── memory/                  # 项目永久记忆 (mistakes/lessons/decisions)
```

详细结构和各文件角色请参考 [`.claude/README.md`](.claude/README.md)。

---

## 🧪 拦截/自动化一览

| 拦截项目 | 位置 |
|---|---|
| `rm -rf /` `~` `*` `.`、`mkfs`、`dd`、fork bomb、`sudo`、`chmod -R 777`、`curl\|sh` | `block-dangerous.sh` |
| `git push --force`、`reset --hard`、`clean -fd`、`--no-verify` | `block-dangerous.sh` + `settings.json` |
| `.env`、`id_rsa`、`~/.ssh/*`、`~/.aws/credentials` 读/写 | `protect-paths.sh` + `settings.json` |
| `/etc`、`/usr`、`.git/`、`node_modules/`、`dist/` 写入 | `protect-paths.sh` |
| 手动编辑 lockfile（`package-lock.json`、`Cargo.lock`、…） | `protect-paths.sh` |

| 自动行为 | 位置 |
|---|---|
| 会话开始时注入历史错误/教训 + 进化状态 | `session-start.sh` |
| 每次提示时注入 git 分支/dirty 状态 | `inject-context.sh` |
| 文件编辑后按语言自动运行格式化器 | `auto-format.sh` |
| 工具失败时自动记录到 mistakes.md | `record-mistake.sh` |
| 未验证就尝试结束时阻止 | `verify-before-stop.sh` |
| 检测重复错误 → 建议进化 | `trigger-evolution.sh` |

---

## 🧬 `/venom` —— 完全吸收项目

一次 `/venom` 即可让 Venom 完全渗透项目：

- **领域深度分析** —— 架构模式、领域模型、开发模式目录
- **10~15 个文件代码采样** —— 观察风格、命名、错误处理约定
- **生成项目定制 rules** —— `60-project.md`、`61-architecture.md`、
  `62-domain.md`、`63-patterns.md`
- **生成项目定制 skills** —— 构建、架构、领域指南等
- **进化现有 rules/skills/hooks** —— 替换为该项目的实际约定
- **生成新 hooks** —— 架构保护、领域保护、质量强制等
- **播种自我进化机制** —— 此后每次会话自动学习和成长
- **变更前自动备份** —— 保存在 `.claude/.venom-backup/`

详细流程请参考 [`.claude/commands/venom.md`](.claude/commands/venom.md)。

## 🫀 活体进化

`/venom` 执行之后 Venom 依然活着：

| 触发条件 | 进化行为 |
|---|---|
| 同一错误出现 2 次 | 强化规则或自动生成 hook |
| 同一模式出现 3 次 | 自动提取为 skill |
| 用户纠正 | 将惯例添加到规则中 |
| 会话开始 | 自动提示需要进化的领域 |
| 会话结束 | 检测重复错误 → 建议进化 |

详细协议请参考 `.claude/rules/55-self-evolution.md`。

---

## 🤝 一起来建设

Venom 的愿景是 **所有 Claude Code 用户共同培育的公共工作环境**。
以下贡献均受欢迎：

- 🐛 **Bug 报告** —— hook 误触发、错误拦截、遗漏的危险模式
- 💡 **新 hook/skill/rule 提案** —— 如果在其他项目验证过，
  欢迎泛化后提交到本仓库
- 🌍 **语言/技术栈覆盖扩展** —— 为 `auto-format.sh` 添加新格式化器，
  为 `test-runner` 添加新测试运行器，为 `venom.md` 添加新清单文件识别
- 🧬 **按项目进化配方** —— 提交针对特定框架（Next.js、FastAPI、Spring、
  Rails 等）的专用进化配方
- 🌐 **翻译** —— 当前提供韩语 + 英语 + 中文。欢迎其他语言翻译
- 📚 **使用案例·反馈** —— 在 Discussions 中分享 Venom 在您项目中的表现。
  误拦截的案例、成功拦截的事故，都很有价值

### 贡献指南（简版）

1. 请先开 issue。大变更先达成共识最快。
2. PR 要小，一个 PR 一个变更。
3. 添加新 hook/skill/rule 时：
   - 在 README 或文件头部说明它做什么、为什么需要
   - 尽量在 PR 描述中附上冒烟测试命令
   - 如有语言/技术栈依赖请明确标注（Venom 的核心价值是 *语言无关*）
4. 对 CLAUDE.md 和 `.claude/rules/00-core.md` 的安全规则做*放松*的变更
   会非常保守地审查。*收紧*的变更则受欢迎。
5. 提交信息推荐使用 conventional commits（`feat:`、`fix:`、`docs:`、…）。

### 行为准则

相互尊重，就事论事，欢迎新人。
详情请参阅 [Contributor Covenant](https://www.contributor-covenant.org/)。

---

## 📜 许可证

MIT。自由复制·修改·再分发。使用 Venom 构建的项目不继承 Venom 的许可证。

---

## 🙏 致谢

Venom 构建在 [Claude Code](https://code.claude.com) 的 hooks·skills·slash
commands 系统之上。感谢 Anthropic 的
[官方文档](https://code.claude.com/docs)、[Skill 编写最佳实践](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
以及社区中所有的 hook 实验。

---

> *"好的工具不会让用户变得更聪明。它让用户无法犯蠢。
> 而最好的工具，每天都在让自己变得更聪明。"*
> —— Venom 的设计哲学
