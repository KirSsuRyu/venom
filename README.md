# 🐍 Venom

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Works with Claude Code](https://img.shields.io/badge/works%20with-Claude%20Code-8A4FFF)](https://code.claude.com)
[![Changelog](https://img.shields.io/badge/changelog-📋-blue.svg)](CHANGELOG.md)
[![English](https://img.shields.io/badge/lang-English-blue.svg)](README.en.md)
[![简体中文](https://img.shields.io/badge/lang-简体中文-green.svg)](README.zh-CN.md)
[![繁體中文](https://img.shields.io/badge/lang-繁體中文-orange.svg)](README.zh-TW.md)

> **Claude Code를 위한, 어떤 프로젝트에도 5초 만에 주입되는 범용 작업 가이드라인**

Venom은 Claude Code가 모든 개발 프로젝트에서 일관되게 안전하고, 일관되게
검증되고, 일관되게 자기 교정을 할 수 있도록 만드는 **드롭인(drop-in) 작업
가이드라인 세트**입니다. 한 번 복사해 넣고 `/venom` 한 번이면 그 프로젝트는
즉시 무장됩니다.

이름은 **"독을 주입해 진화시킨다"** 는 컨셉에서 왔습니다. Venom은 단순한
규칙 모음이 아니라, 프로젝트에 침투하여 자기 자신을 그 프로젝트에 맞게
*변태(metamorphose)*시키고, **일하면서 계속 배우고 진화하는 살아있는
심비오트**입니다.

---

## ✨ Venom이 해 주는 것

- 🛡️ **결정적 안전장치** — `rm -rf /`, `git push --force`, `.env` 누설,
  락파일 손편집 같은 사고를 hook이 100% 차단합니다. CLAUDE.md는 권고고,
  hook은 강제입니다.
- 🧠 **자기 교정 메모리** — Claude가 저지른 실수, 거부된 시도(`PermissionDenied`),
  API 에러로 끝난 턴(`StopFailure`)이 `.claude/memory/mistakes.md`에 자동
  기록되고, 다음 세션 시작 시 컨텍스트에 다시 주입됩니다.
  *같은 실수를 두 번 하지 않습니다.*
- 💰 **토큰 절감** — 하네스 자체가 토큰 비용을 줄이도록 설계됐습니다.
  SessionStart 주입은 placeholder/형식 예시를 제거하고 최근 N개 항목만
  주입합니다. 거부될 도구 호출이 다음 세션에서 반복되지 않도록 학습되고,
  검증 게이트가 무의미한 재시도를 사전에 차단합니다. *하네스는 비용이
  아니라 절약입니다.*
- 🧬 **프로젝트별 진화** — `/venom` 한 줄로 Venom이 프로젝트의 도메인·아키텍처·
  패턴을 심층 분석하고, rules·skills·hooks를 그 프로젝트에 맞게 *진화*시킵니다.
  변경 전엔 자동으로 `.claude/.venom-backup/`에 백업합니다.
- 🫀 **살아있는 자기 진화** — `/venom` 이후에도 Venom은 살아 숨쉽니다.
  같은 실수 2회 → 규칙/hook 자동 강화, 같은 패턴 3회 → 스킬 자동 추출,
  매 세션 시작 시 진화 필요 영역 알림, 매 세션 종료 시 진화 기회 감지.
- 🌐 **언어 무관** — Python, JS/TS, Go, Rust, Java, Ruby, PHP… 어디서든
  동작합니다. 특정 언어 감지는 런타임에 일어나고, 없으면 조용히 패스합니다.
- 📦 **드롭인** — 단 두 항목(`CLAUDE.md`와 `.claude/`)을 프로젝트 루트에
  복사하면 끝입니다. 의존성 없음, 설치 스크립트 없음, 백그라운드 프로세스 없음.

---

## 🚀 빠른 시작

### 권장: npm CLI 한 줄

```bash
cd /path/to/your-project
npx @cgyou/venom-init
```

이 명령은 다음을 수행합니다:

1. 현재 디렉토리에 `CLAUDE.md` 와 `.claude/` 를 설치합니다.
2. 이미 존재하면 `.venom-backup/<timestamp>/` 로 자동 백업한 뒤 덮어씁니다.
3. `.claude/settings.local.json` (사용자 로컬 권한 토글)은 **항상 보존**합니다.
4. hook 스크립트의 실행 비트를 자동으로 부여하고, `.gitignore` 에
   `.venom-backup/` 을 추가합니다.

옵션:

```bash
npx @cgyou/venom-init --dry-run        # 변경 없이 계획만 출력
npx @cgyou/venom-init --from-git       # 동봉본 대신 GitHub main에서 직접 가져오기
npx @cgyou/venom-init --from-git --ref some-branch
npx @cgyou/venom-init --no-backup --force   # 백업 없이 덮어쓰기 (위험)
```

설치 후 Claude Code 세션에서 한 번:

```
/venom            # 프로젝트 완전 흡수 — 도메인·아키텍처·패턴 분석 후 전체 진화
```

### 수동: git clone

CLI 를 쓰고 싶지 않다면 여전히 수동으로 가능합니다.

```bash
git clone https://github.com/KirSsuRyu/venom.git
cp -r venom/CLAUDE.md venom/.claude /path/to/your-project/
chmod +x /path/to/your-project/.claude/hooks/*.sh
```

끝입니다. 이제 그 프로젝트에서 Claude Code는:

- 위험 명령을 절대 실행하지 못하고,
- 비밀 파일을 절대 읽거나 쓰지 못하고,
- 변경 후 자동으로 포맷·검증을 거치고,
- 실수하면 그 자리에서 메모리에 기록하고,
- 다음 세션에서 그 실수를 컨텍스트에 들고 시작합니다.

---

## 📦 무엇이 들어 있나

```
your-project/
├── CLAUDE.md                    # Claude Code가 매 세션 자동 로드하는 상위 가이드라인
└── .claude/
    ├── README.md                # .claude/ 폴더 내부 가이드
    ├── settings.json            # 권한·hook 등록·환경 변수
    ├── commands/
    │   └── venom.md             # /venom 슬래시 명령
    ├── rules/                   # 자동 로드되는 7개 도메인 규칙 (00-55)
    ├── skills/                  # 8개 범용 스킬 (review/debug/test/git/memory/evolve/retro/compact)
    ├── hooks/                   # 10개 결정적 강제 스크립트
    └── memory/                  # 프로젝트 영구 메모리 (mistakes/lessons/decisions)
```

자세한 구조와 각 파일의 역할은 [`.claude/README.md`](.claude/README.md) 참고.

---

## 🧪 차단/자동화 한눈에 보기

| 차단 항목 | 어디서 |
|---|---|
| `rm -rf /` `~` `*` `.`, `mkfs`, `dd`, fork bomb, `sudo`, `chmod -R 777`, `curl\|sh` | `block-dangerous.sh` |
| `git push --force`, `reset --hard`, `clean -fd`, `--no-verify` | `block-dangerous.sh` + `settings.json` |
| `.env`, `id_rsa`, `~/.ssh/*`, `~/.aws/credentials` 읽기/쓰기 | `protect-paths.sh` + `settings.json` |
| `/etc`, `/usr`, `.git/`, `node_modules/`, `dist/` 쓰기 | `protect-paths.sh` |
| 락파일 수동 편집 (`package-lock.json`, `Cargo.lock`, …) | `protect-paths.sh` |

| 자동 동작 | 어디서 |
|---|---|
| 세션 시작 시 과거 실수/교훈 + 진화 상태 주입 | `session-start.sh` |
| 매 프롬프트마다 git 브랜치/dirty 상태 주입 | `inject-context.sh` |
| 파일 편집 후 언어별 포매터 자동 실행 | `auto-format.sh` |
| 도구 실패 시 mistakes.md 자동 기록 | `record-mistake.sh` |
| 검증 없이 종료 시도 시 차단 | `verify-before-stop.sh` |
| 반복 실수 감지 → 진화 권고 | `trigger-evolution.sh` |

---

## 🧬 `/venom` — 프로젝트 완전 흡수

`/venom` 한 번이면 Venom이 프로젝트에 완전히 침투합니다:

- **도메인 심층 분석** — 아키텍처 패턴, 도메인 모델, 개발 패턴 카탈로그
- **10~15개 파일 코드 샘플링** — 스타일, 네이밍, 에러 처리 컨벤션 관찰
- **프로젝트 맞춤 rules 생성** — `60-project.md`, `61-architecture.md`,
  `62-domain.md`, `63-patterns.md`
- **프로젝트 맞춤 skills 생성** — 빌드, 아키텍처, 도메인 가이드 등
- **기존 rules/skills/hooks 진화** — 그 프로젝트의 실제 컨벤션으로 교체
- **신규 hooks 생성** — 아키텍처 보호, 도메인 보호, 품질 강제 등
- **자기 진화 씨앗 심기** — 이후 매 세션마다 자동으로 배우고 성장
- **변경 전 자동 백업** — `.claude/.venom-backup/`에 보관

자세한 절차는 [`.claude/commands/venom.md`](.claude/commands/venom.md) 참고.

## 🫀 살아있는 진화

`/venom` 실행 이후에도 Venom은 살아 숨쉽니다:

| 트리거 | 진화 행동 |
|---|---|
| 같은 실수 2회 | 규칙 강화 또는 hook 자동 생성 |
| 같은 패턴 3회 | 스킬로 자동 추출 |
| 사용자 교정 | 관례를 규칙에 추가 |
| 세션 시작 | 진화 필요 영역 자동 알림 |
| 세션 종료 | 반복 실수 감지 → 진화 권고 |

자세한 프로토콜은 `.claude/rules/55-self-evolution.md` 참고.

---

## 🤝 함께 만들어요

Venom은 **모든 Claude Code 사용자가 함께 키워가는 공용 작업 환경**을
지향합니다. 다음은 모두 환영합니다.

- 🐛 **버그 리포트** — hook 오작동, 잘못된 차단, 누락된 위험 패턴
- 💡 **신규 hook/skill/rule 제안** — 다른 프로젝트에서 검증된 패턴이라면
  이 저장소에 일반화해서 올려 주세요
- 🌍 **언어/스택 커버리지 확장** — `auto-format.sh`에 새 포매터, `test-runner`
  스킬에 새 테스트 러너, `venom.md`에 새 매니페스트 파일 인식 추가
- 🧬 **프로젝트별 진화 레시피** — 특정 프레임워크(Next.js, FastAPI, Spring,
  Rails 등)에 특화된 진화 레시피를 PR로 제출
- 🌐 **번역** — 현재 한국어 + 영어 혼용. 다른 언어 번역 환영
- 📚 **사용 사례·후기** — 여러분의 프로젝트에서 Venom이 어떻게 동작했는지
  Discussions에 공유해 주세요. 잘못 차단된 사례, 잘 잡아낸 사고, 모두 좋습니다

### 기여 가이드 (간단 버전)

1. 이슈를 먼저 열어 주세요. 큰 변경은 사전 합의가 가장 빠릅니다.
2. PR은 작게, 한 PR에 한 변경.
3. 새 hook/skill/rule을 추가했다면:
   - 무엇을 하는지, 왜 필요한지 README나 해당 파일 상단에 명시
   - 가능하면 스모크 테스트 명령을 PR 설명에 포함
   - 언어/스택 종속이 있다면 명시 (Venom의 기본 가치는 *언어 무관*입니다)
4. CLAUDE.md와 `.claude/rules/00-core.md`가 정한 안전 규칙은 *느슨하게 만드는*
   변경은 매우 보수적으로 검토합니다. 더 *조이는* 변경은 환영합니다.
5. 커밋 메시지는 conventional commits (`feat:`, `fix:`, `docs:`, …) 권장.

### 행동 강령

서로 존중하고, 코드와 사람을 분리해서 이야기하고, 새로운 사람을 환대해
주세요. 자세한 내용은 [Contributor Covenant](https://www.contributor-covenant.org/)를
따릅니다.

---

## 📜 라이선스

MIT. 자유롭게 복사·수정·재배포하세요. Venom으로 만들어진 어떤 프로젝트도
Venom의 라이선스를 상속받지 않습니다.

---

## 🙏 감사

Venom은 [Claude Code](https://code.claude.com)의 hooks·skills·slash commands
시스템 위에 만들어졌습니다. Anthropic의 [공식 문서](https://code.claude.com/docs)와
[Skill 작성 베스트 프랙티스](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices),
그리고 커뮤니티의 모든 hook 실험들에 빚지고 있습니다.

---

> *"좋은 도구는 사용자를 더 똑똑하게 만들지 않는다. 사용자가 멍청해지지
> 못하게 한다. 그리고 가장 좋은 도구는 매일 스스로 더 똑똑해진다."*
> — Venom의 설계 철학
