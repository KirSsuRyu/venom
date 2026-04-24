# `.claude/` — Claude Code 작업 환경

이 폴더는 이 프로젝트에서 Claude Code가 따라야 할 규칙·스킬·훅·메모리를 담습니다.
프로젝트 루트의 `CLAUDE.md`와 함께 동작합니다.

## 구조

```
CLAUDE.md                        # ← 프로젝트 루트. 매 세션 자동 로드되는 상위 가이드라인
.claude/
├── README.md                    # 이 파일
├── settings.json                # 권한, hook 등록, 환경 변수
├── commands/                    # 슬래시 명령
│   └── venom.md                # /venom — 프로젝트 완전 흡수
├── rules/                       # 자동 로드되는 세부 규칙 (CLAUDE.md 보강)
│   ├── 00-core.md               # 협상 불가 안전 규칙
│   ├── 10-coding-standards.md   # 포맷·네이밍·구조 (언어 무관)
│   ├── 20-security.md           # 비밀·의존성·인젝션
│   ├── 30-git-commit.md         # 커밋·브랜치·PR 규약
│   ├── 40-testing.md            # 테스트 배치와 기대치
│   ├── 50-memory-protocol.md    # memory/ 사용법
│   └── 55-self-evolution.md     # 자기 진화 프로토콜 (살아있는 심비오트의 심장)
│   # /venom 실행 후 추가되는 파일:
│   # ├── 60-project.md          # 프로젝트 특화 규칙
│   # ├── 61-architecture.md     # 아키텍처 레이어·모듈 경계
│   # ├── 62-domain.md           # 도메인 용어·불변 규칙
│   # └── 63-patterns.md         # 개발 패턴 카탈로그
├── agents/                      # 격리 실행 서브에이전트 (공식 스펙)
│   ├── code-reviewer.md         # diff·PR·변경사항 리뷰
│   ├── debug-detective.md       # 가설–검증 디버깅 (Iron Law 3회 제한)
│   ├── test-writer.md           # 누락 테스트 작성·TDD·회귀
│   └── security-auditor.md      # OWASP Top 10 감사
├── output-styles/               # 출력 스타일 (공식 스펙)
│   └── venom-default.md         # 5계명 톤 + 4섹션 보고 템플릿
├── skills/                      # 트리거 기반 스킬 (메인 컨텍스트 절차 안내)
│   ├── compact-guide/           # 전략적 컴팩션 타이밍 가이드
│   ├── git-workflow/            # 안전한 커밋·PR 절차
│   ├── mistake-recorder/        # 실수를 메모리에 영구 기록
│   ├── retro/                   # 주간/세션 회고
│   └── evolve/                  # 자기 진화 엔진 (규칙·스킬·hook 생성/보강)
│   # /venom 실행 후 추가되는 스킬:
│   # ├── project-build/         # 프로젝트 빌드/테스트/린트 명령
│   # ├── project-architecture/  # 모듈 트리·레이어·API 경계
│   # └── project-domain/        # 도메인 지식 가이드
├── hooks/                       # 결정적 강제 (절대 일어나야 하는 것)
│   ├── session-start.sh             # SessionStart: 메모리 + 진화 상태 주입
│   ├── inject-context.sh            # UserPromptSubmit: git 상태 주입
│   ├── scan-secrets.sh              # UserPromptSubmit: 비밀 값 노출 감지
│   ├── block-dangerous.sh           # PreToolUse(Bash): 파괴적 명령 차단
│   ├── lib/dangerous-patterns.sh    #   └─ 위험 패턴 단일 진실원천
│   ├── lib/evolution-analyzer.sh    #   └─ mistakes.md 분석 공유 로직
│   ├── lib/stop-guard.sh            #   └─ Stop 훅 질문 감지 공통
│   ├── protect-paths.sh             # PreToolUse(Write|Edit): 보호 경로 차단
│   ├── auto-format.sh               # PostToolUse: 언어별 포매터 자동 실행
│   ├── record-mistake.sh            # PostToolUseFailure: 실수 자동 기록
│   ├── record-permission-denied.sh  # PermissionDenied: 거부 자동 기록
│   ├── record-stop-failure.sh       # StopFailure: API 에러 자동 기록
│   ├── verify-before-stop.sh        # Stop: 검증 안 한 채 종료 방지
│   ├── trigger-evolution.sh         # Stop: 반복 실수 감지 → 진화 큐잉
│   ├── session-end-reminder.sh      # SessionEnd: 세션 종료 알림
│   └── statusline.sh                # statusLine: 브랜치·진화 대기·실수 카운트
└── memory/                      # 영구 프로젝트 메모리 (저장소에 커밋)
    ├── README.md
    ├── mistakes.md              # 자동 기록 + Claude가 채우는 교훈
    ├── lessons.md               # 항구적 교훈
    └── decisions.md             # 아키텍처 결정 (ADR)
```

## 핵심 설계

- **살아있는 심비오트** — Venom은 1회성 도구가 아니다. `/venom`으로 프로젝트에
  침투하고, 일하면서 배우고, 스스로 규칙·스킬·hook을 진화시킨다.
  같은 실수 2회 → 규칙/hook 강화, 같은 패턴 3회 → 스킬 추출.
- **언어 무관** — Python, JS/TS, Go, Rust, Java, Ruby 등 어디서든 동작.
- **권고와 강제의 분리** — `CLAUDE.md`/`rules/`는 판단을 인도(Claude는 ~80%
  준수), `hooks/`는 100% 결정적으로 강제. "매번 일어나야 한다"면 hook이다.
- **자기 교정 메모리** — 도구 실패(`PostToolUseFailure`), 권한 거부
  (`PermissionDenied`), 턴 실패(`StopFailure`)가 `mistakes.md`에 자동 기록되고
  다음 세션 시작 시 컨텍스트에 주입되어 같은 실수가 반복되지 않는다.
- **토큰 절감** — `session-start.sh`는 placeholder/형식 예시를 필터링하고
  최근 N개 항목만 주입한다. 빈 메모리 파일은 통째로 스킵. 매 세션·매 프롬프트
  에 들어가는 hook 출력은 의도적으로 작게 유지한다.
- **자기 진화** — `trigger-evolution.sh`가 매 세션 종료 시 반복 실수를 감지하고,
  `session-start.sh`가 세션 시작 시 진화 필요 영역을 알린다.
  `evolve` 스킬이 실제 규칙·스킬·hook 생성을 안내한다.

## 첫 실행

이 폴더가 새 프로젝트에 막 복사되었다면 Claude Code에서 한 번:

```
/venom            # 프로젝트 완전 흡수 — 도메인·아키텍처·패턴 분석 후 전체 진화
```

## 차단 / 자동화 요약

| 차단 | 어디서 |
|---|---|
| `rm -rf /` `~` `*` `.`, `mkfs`, `dd`, fork bomb, `sudo`, `chmod -R 777`, `curl\|sh` | `block-dangerous.sh` |
| `git push --force`, `reset --hard`, `clean -fd`, `--no-verify` | `block-dangerous.sh` + `settings.json` |
| `.env`, `id_rsa`, `~/.ssh/*`, `~/.aws/credentials` 읽기/쓰기 | `protect-paths.sh` + `settings.json` |
| `/etc`, `/usr`, `.git/`, `node_modules/`, `dist/` 쓰기 | `protect-paths.sh` |
| 락파일 수동 편집 | `protect-paths.sh` |

| 자동 동작 | 어디서 |
|---|---|
| 세션 시작 시 과거 실수/교훈 + 진화 상태 주입 | `session-start.sh` |
| 매 프롬프트마다 git 브랜치/dirty 상태 주입 | `inject-context.sh` |
| 파일 편집 후 언어별 포매터 자동 실행 | `auto-format.sh` |
| 도구 실패 시 mistakes.md 자동 기록 | `record-mistake.sh` |
| 검증 없이 종료 시도 시 차단 | `verify-before-stop.sh` |
| 반복 실수 감지 → 진화 권고 | `trigger-evolution.sh` |

## 커스터마이징

이 폴더를 직접 손대기보다 `/venom`를 먼저 돌리세요. 그래도 부족하면:

- 프로젝트 규칙 → `.claude/rules/60-project.md` 등 `60-`/`70-` 접두어로 추가
- 프로젝트 스킬 → `.claude/skills/project-<name>/SKILL.md`
- 프로젝트 훅 → `.claude/hooks/`에 스크립트 추가 후 `settings.json`에 등록
- 환경 변수 → `.claude/settings.json`의 `env` 블록
- 자기 진화 → `55-self-evolution.md` 프로토콜에 따라 자동으로 성장

## 참고

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Extend Claude with Skills](https://code.claude.com/docs/en/skills)
- [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
