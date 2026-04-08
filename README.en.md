# 🐍 Venom

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Works with Claude Code](https://img.shields.io/badge/works%20with-Claude%20Code-8A4FFF)](https://code.claude.com)
[![한국어](https://img.shields.io/badge/lang-한국어-red.svg)](README.md)

> **A drop-in working harness for Claude Code that injects into any project in 5 seconds**

Venom makes Claude Code consistently safe, consistently verified, and
consistently self-correcting in every project. Copy two items, run `/venom`,
and that project is armed.

The name comes from the concept of *injecting venom to evolve*. Venom is not
just a rule pack — it's a living working environment that *metamorphoses*
itself to fit the project it lives in.

---

## ✨ What Venom does for you

- 🛡️ **Deterministic safety** — `rm -rf /`, `git push --force`, `.env`
  exfiltration, hand-edited lockfiles — hooks block all of them 100% of the
  time. CLAUDE.md is advisory; hooks are enforcement.
- 🧠 **Self-correcting memory** — tool failures (`PostToolUseFailure`),
  permission denials (`PermissionDenied`), and turn failures (`StopFailure`)
  are auto-recorded to `.claude/memory/mistakes.md` and re-injected on the
  next session. *Same mistake never twice.*
- 💰 **Token savings** — the harness itself is designed to reduce token cost.
  SessionStart injection filters out placeholder/format examples and only
  emits the latest N entries. Denied tool calls are remembered so the next
  session doesn't retry them. Verification gates kill pointless retries
  before they spend tokens. *The harness is a saving, not a cost.*
- 🧬 **Per-project evolution** — `/venom deep` analyzes the project and
  *evolves* rules, skills, and hooks to fit its stack, conventions, CI gates,
  and forbidden patterns. Backups are written to `.claude/.venom-backup/`.
- 🌐 **Language-agnostic** — Python, JS/TS, Go, Rust, Java, Ruby, PHP… works
  everywhere. Language detection happens at runtime; missing tools fail silent.
- 📦 **Drop-in** — only two items (`CLAUDE.md` and `.claude/`) need to land in
  the project root. No dependencies, no install scripts required, no
  background processes.

---

## 🚀 Quick start

### Recommended: one-line npm CLI

```bash
cd /path/to/your-project
npx @kirssu/venom-init
```

This will:

1. Install `CLAUDE.md` and `.claude/` into the current directory.
2. If they already exist, back them up to `.venom-backup/<timestamp>/` first.
3. Always **preserve** `.claude/settings.local.json` (your local permission toggles).
4. Mark hook scripts executable and add `.venom-backup/` to `.gitignore`.

Options:

```bash
npx @kirssu/venom-init --dry-run        # plan only, no writes
npx @kirssu/venom-init --from-git       # fetch from GitHub main instead of bundled copy
npx @kirssu/venom-init --from-git --ref some-branch
npx @kirssu/venom-init --no-backup --force   # overwrite without backup (dangerous)
```

Then in a Claude Code session inside that project:

```
/venom            # standard absorption (recommended)
/venom deep       # deep absorption — evolves Venom itself for this project
```

### Manual: git clone

```bash
git clone https://github.com/KirSsuRyu/venom.git
cp -r venom/CLAUDE.md venom/.claude /path/to/your-project/
chmod +x /path/to/your-project/.claude/hooks/*.sh
```

That's it. From this point on, Claude Code in that project:

- Cannot run dangerous commands,
- Cannot read or write secret files,
- Auto-formats and verifies after edits,
- Records mistakes to memory the moment they happen,
- Loads those mistakes back into context on the next session.

---

## 🧪 Block / automation cheatsheet

| Blocked | Where |
|---|---|
| `rm -rf /` `~` `*` `.`, `mkfs`, `dd`, fork bomb, `sudo`, `chmod -R 777`, `curl\|sh` | `block-dangerous.sh` + `lib/dangerous-patterns.sh` |
| `git push --force`, `reset --hard`, `clean -fd`, `--no-verify` | `block-dangerous.sh` + `settings.json` |
| `.env`, `id_rsa`, `~/.ssh/*`, `~/.aws/credentials` read/write | `protect-paths.sh` + `settings.json` |
| `/etc`, `/usr`, `.git/`, `node_modules/`, `dist/` writes | `protect-paths.sh` |
| Hand-editing lockfiles | `protect-paths.sh` |

| Automation | Where |
|---|---|
| Inject memory at session start (filtered, capped) | `session-start.sh` |
| Inject git branch + dirty count on every prompt | `inject-context.sh` |
| Auto-format edited files (language-detected) | `auto-format.sh` |
| Record tool failures to mistakes.md | `record-mistake.sh` |
| Record denied tool calls to mistakes.md | `record-permission-denied.sh` |
| Record API turn failures to mistakes.md | `record-stop-failure.sh` |
| Block stop without verification | `verify-before-stop.sh` |

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## 📜 License

MIT. See [LICENSE](LICENSE). Projects built with Venom do **not** inherit
Venom's license.

---

> *"A good tool doesn't make its user smarter. It makes them unable to be
> stupid."* — Venom's design philosophy
