# Changelog

이 프로젝트는 [Semantic Versioning](https://semver.org/)을 따릅니다.
형식은 [Keep a Changelog](https://keepachangelog.com/)를 참고합니다.

## [2.0.11] — 2026-04-16

### Fixed
- **bash 3.2 `heredoc-in-$()` 버그 대응** — macOS 기본 bash(3.2)에서 `$()`
  안 heredoc 내용에 `)`가 있으면 명령 치환이 조기 종료되는 버그 수정.
  `scan-secrets.sh`와 `lib/stop-guard.sh`의 Python 스크립트를 `mktemp` 임시
  파일로 분리하고 `trap`으로 자동 정리. 이전 단순 `<<'PYEOF'` → `<<PYEOF`
  변경은 `'` 문제만 해결했고 `)` 문제는 미해결 상태였음.
- **hook 실행 권한 누락 수정** — git clone 후 `trigger-evolution.sh`,
  `lib/dangerous-patterns.sh`, `lib/stop-guard.sh`, `scan-secrets.sh`에
  실행 비트(`+x`) 누락으로 Permission denied 발생하던 문제 수정.

## [2.0.9] — 2026-04-16

### Added
- **`scan-secrets.sh` 훅 신규** — UserPromptSubmit 이벤트에서 사용자 메시지의
  시크릿 패턴을 스캔. OpenAI/Anthropic(`sk-`), GitHub PAT(`ghp_`/`ghs_`), AWS
  Access Key(`AKIA`), Slack 토큰(`xox*`), Bearer 토큰, PEM 개인키, DB 연결 문자열
  등 13개 패턴 탐지. 감지 시 Claude 컨텍스트에 `⛔ VENOM SECURITY ALERT` 경고
  주입 → 자격증명 사용 거부 및 rotate 안내. python3 없거나 감지 없는 경우 토큰
  비용 0. ECC의 PreSubmitPrompt 시크릿 스캔 개념을 Venom에 통합.
  `settings.json` UserPromptSubmit 배열에 등록.
- **`compact` 스킬 신규** — 전략적 컴팩션 타이밍 가이드. "지금 압축해야 하는
  신호 6가지 / 하면 안 되는 신호 4가지" 판단 기준, 압축 전 5항목 체크리스트,
  압축 후 재시작 팁 포함. Venom의 토큰 절감 핵심 목표와 연결. ECC의
  전략적 컴팩션 가이드 개념 통합.

### Changed
- **`block-dangerous.sh`에 `VENOM_HOOK_PROFILE` 엄격도 프로파일 추가** —
  `permissive`(경고만·실행 허용) / `standard`(현재 기본·차단) / `strict`
  (추가 패턴 차단: force-with-lease, chmod -R, chown -R, truncate, /etc/ 쓰기)
  3단계 프로파일 지원. `settings.json` env에 `VENOM_HOOK_PROFILE=standard` 기본값
  추가. ECC의 `ECC_HOOK_PROFILE` 개념을 Venom 네이밍으로 통합.
- **`verify-before-stop.sh` 3단계 검증으로 강화** — 기존 HARD 차단(1단계)에
  SOFT 힌트 2단계 추가. [2단계] 최근 60분 내 mistakes.md 갱신 시 lessons.md
  기록 권고 / [3단계] 최근 3커밋에 feat: 타입 있으면 문서 동기화 확인 권고.
  차단 메시지에 "[1/3 코드 검증]" 레이블 추가로 단계 구조 명확화. ECC의
  다단계 verification-loop 패턴 통합.

## [2.0.8] — 2026-04-16

### Changed
- **`/venom` 커맨드에 스킬 체인 추천 섹션 추가** — 4.10단계(스킬 체인 도출)
  신설: 인증·결제·개인정보 코드 감지 시 보안 감사 모드 명시, 복잡 로직 시
  debug-loop 전면 배치 등 프로젝트 특성 → 스킬 조합 판단 기준 테이블.
  7단계 보고 형식에 `🔗 권장 스킬 체인` 블록 추가: 일반 개발·버그 수정·
  보안 민감·주간 회고 4가지 흐름 템플릿. gstack의 스프린트 파이프라인
  (Think→Plan→Build→Review→Test→Ship→Reflect) 개념을 /venom 흡수 결과물에 통합.
- **`git-workflow` 스킬에 문서 동기화 체크 추가** — 커밋/PR 전 diff와 문서
  불일치를 점검하는 섹션 신설. README·CHANGELOG·CONTRIBUTING·ARCHITECTURE·
  `.env.example` 등 대상별 확인 항목 매핑 테이블, 건너뛸 수 있는 조건(chore/test/
  refactor 타입), PR 본문에 `## Docs` 체크박스 추가. gstack `/document-release`
  개념을 Venom의 git 워크플로우에 통합.
- **`inject-context.sh`에 스킬 힌트 주입 추가** — UserPromptSubmit 시 프롬프트
  키워드를 감지해 적절한 스킬을 1줄로 추천. 디버깅(debug-loop), 보안 감사
  (code-review 보안 모드), 코드 리뷰, 회고(retro), git 작업, 테스트 6가지 단계를
  구분. 키워드 없는 경우 추가 토큰 0. python3 없거나 JSON 파싱 실패 시 조용히
  스킵. gstack의 "단계 감지 → 스킬 제안" 개념을 Venom의 토큰 절감 철학에 맞게 통합.
- **`code-review` 스킬에 OWASP 보안 감사 패스 추가** — "보안 감사해줘" / 인증·결제·
  사용자 데이터 코드 감지 시 자동 실행되는 `🔐 보안 감사 패스` 섹션 신설.
  OWASP Top 10(A01~A10) 체크리스트, 신뢰도 8/10 이상 게이트, 구체적 공격 시나리오
  필수 요건, 7종 false positive 자동 제외 규칙 포함. gstack `/cso`의 zero-noise
  접근법을 Venom 스타일로 통합. 트리거 description에 보안 감사 키워드 추가.
- **`debug-loop` 스킬에 Iron Law 흡수** — "조사 없이 수정하지 않는다 / 수정이 3번
  연속 실패하면 멈추고 보고한다"는 절대 원칙을 스킬 최상단에 명시. 수정 시도
  카운터 개념, 3회 실패 시 보고 형식, 카운터 리셋 금지 안티 패턴 추가.
  기존 단계에 7단계(검증 루프)를 명시적으로 분리하고, Iron Law 발동 시 메모리
  기록을 의무화. gstack `/investigate`의 핵심 방법론을 Venom 스타일로 통합.

### Added
- **`retro` 스킬 신규 추가** — 주간/세션 단위 회고 스킬. git 통계(커밋 수, 추가/삭제
  라인, 변경 파일, 커밋 타입 분포)와 `.claude/memory/` 항목을 결합해 성과·배운 것·
  막힌 곳을 구조화된 리포트로 출력합니다. 진화 신호(반복 태그, fix 비율 이상, 문서
  커밋 부재 등)를 자동 감지해 `evolve` 스킬 실행을 권고합니다. gstack의 `/retro`
  컨셉을 Venom의 메모리·진화 시스템에 맞게 통합.

## [2.0.7] — 2026-04-15

### Fixed
- **Stop 훅 질문 턴 스킵 개선** — `AskUserQuestion` 도구 감지만으로는 Claude가 평문으로
  던지는 질문을 감지하지 못하는 문제 수정. `lib/stop-guard.sh`의 `is_question_stop()`을
  Python3으로 transcript JSONL을 파싱해 마지막 어시스턴트 텍스트를 추출하고,
  `?`·한국어 질문형 어미·승인 대기 문구를 정규식으로 감지하는 방식으로 교체.
  `verify-before-stop.sh`, `trigger-evolution.sh` 양쪽에 동일하게 적용.

## [2.0.6] — 2026-04-15

### Changed
- **진화 메모리 모델 개선** — `mistakes.md`/`lessons.md`를 "진화 대기열(임시)"로,
  `decisions.md`를 "진화 영구 이력"으로 역할을 명확히 분리.
  진화 완료 시 원본 항목을 `decisions.md`에 흡수 후 삭제하는 "승급 후 소멸" 모델 도입.
  세션마다 "이미 해결된 실수"에 컨텍스트가 낭비되는 문제 해소.
- **`decisions.md` ADR 형식에 `기원` 필드 추가** — 어떤 실수/교훈에서 규칙이 비롯됐는지
  추적 가능. 삭제된 원본 항목의 이력을 ADR에서 확인할 수 있음.
- **진화 생성 파일 배치 규칙 신설** — 자기 진화로 새로 생성되는 규칙·스킬·훅은
  각 폴더의 `evolved/` 서브폴더에 배치. 기존 기반 파일과 명확히 분리.
  ```
  rules/evolved/<이름>.md
  hooks/evolved/<이름>.sh
  skills/evolved/<이름>/SKILL.md
  ```
- `50-memory-protocol.md`, `55-self-evolution.md`, `evolve/SKILL.md` — 위 변경 반영.

## [2.0.4] — 2026-04-13

### Changed
- `venom-init.mjs` — 업그레이드 시 전체 덮어쓰기 → 파일 소유권 기반 스마트 병합으로 교체.
  - **하네스 소유** (항상 갱신): `hooks/`, `rules/00-59`, 기본 스킬 6개, `settings.json`, `CLAUDE.md` 등
  - **사용자 소유** (이미 있으면 보존): `rules/60+`(/venom 생성), `memory/*.md`(누적 데이터), `project-*` 스킬
  - `--force` 플래그로 사용자 소유 파일까지 강제 덮어쓰기 가능
  - 업그레이드 결과 요약 출력: "N개 갱신, M개 신규, K개 보존"
  - `isHarnessOwned()` 함수로 파일 소유권 판단 로직을 단일 지점에 집중

## [2.0.3] — 2026-04-13

### Fixed
- `session-start.sh` — `lessons.md`를 읽지 못하는 버그 수정. `emit_recent_sections()`는
  `## ` 헤더 기준 섹션 파서라 `- [#tag]` 불릿 형식인 `lessons.md`에서 항목을 0개 추출했음.
  전용 `emit_lessons()` 함수를 추가하여 불릿 항목을 올바르게 파싱.
- `session-start.sh` — HTML 주석(`<!-- -->`) 안의 `## ` 헤더가 실제 섹션으로
  카운트되던 버그 수정. 형식 예시 주석이 컨텍스트 토큰을 낭비하지 않도록 awk에 주석 감지 로직 추가.
- `record-mistake.sh` — 자동 생성 항목에 태그 라인이 없어 `trigger-evolution.sh`의
  반복 실수 감지가 작동하지 않던 문제 수정. 필드명을 `50-memory-protocol.md` 규약
  (`맥락/한 일/왜 틀렸나/옳은 접근/태그`)에 맞게 통일. 파일 초기화 시 한글 헤더로 수정.
- `record-permission-denied.sh` — 태그 라인 누락 수정, 필드명 규약 통일.
- `record-stop-failure.sh` — 태그 라인 누락 수정, 필드명 규약 통일.

### Changed
- `memory/mistakes.md`, `memory/lessons.md`, `memory/decisions.md` — npm 패키지 배포용
  초기 상태로 리셋. 개발 중 적재된 내용 제거, 형식 가이드/예시만 유지.

## [2.0.1] — 2026-04-11

### Fixed
- `trigger-evolution.sh` — Stop 훅의 JSON 출력 형식 수정. `hookSpecificOutput.additionalContext`
  구조는 Stop 훅 스키마에 존재하지 않아 "Hook JSON output validation failed: Invalid input"
  에러를 유발했음. 올바른 `{"decision":"block","reason":"..."}` 형식으로 교체.
  다른 프로젝트에 venom 설치 시 매 턴 종료마다 stop hook error가 발생하는 이슈 해결.

## [2.0.0] — 2026-04-11

### Added — 살아있는 심비오트
- **자기 진화 프로토콜** (`55-self-evolution.md`) — 같은 실수 2회 → 규칙/hook
  강화, 같은 패턴 3회 → 스킬 추출, 사용자 교정 → 관례를 규칙에 추가.
  Venom을 1회성 도구에서 살아있는 심비오트로 전환.
- **진화 스킬** (`evolve/SKILL.md`) — 규칙·스킬·hook·메모리 진화를 안내하는
  구조화된 절차. 진화 유형 판단 기준표, 7단계 절차, 안티 패턴 포함.
- **진화 트리거 hook** (`trigger-evolution.sh`) — Stop 이벤트에서 `mistakes.md`를
  스캔하여 반복 실수 태그 감지 → Claude에게 진화 권고.
- `session-start.sh`에 진화 상태 주입 — 반복 실수 태그가 있으면 세션 시작 시
  "Evolution needed" 알림으로 진화 필요 영역 즉시 인식.
- `/venom` 8단계 "자기 진화 씨앗 심기" — 흡수 완료 후 진화 메커니즘이
  심어져 있는지 자동 검증.

### Added — /venom 강화
- `/venom`이 항상 최대 깊이로 동작 (quick/standard/deep 모드 제거).
- 3B 아키텍처 패턴 분석, 3C 도메인 모델 분석, 3D 개발 패턴 카탈로그.
- 10~15개 파일 심층 코드 샘플링 (허브 모듈 포함).
- `61-architecture.md`, `62-domain.md`, `63-patterns.md` 자동 생성.
- `project-domain/SKILL.md` 도메인 지식 가이드 스킬.
- 15종 스킬 후보 + 9종 hook 후보 (프로젝트에 맞는 것만 선별 생성).
- 아키텍처 보호 hook, 도메인 보호 hook, 품질 강제 hook, 컨텍스트 주입 hook.

### Added — 기존 항목
- `PermissionDenied` hook (`record-permission-denied.sh`) — 거부된 도구 호출을
  mistakes.md에 자동 기록. 다음 세션이 같은 시도를 안 하게 함(토큰 절감).
- `StopFailure` hook (`record-stop-failure.sh`) — API 에러 유형별 회고.
  `rate_limit`/`max_output_tokens`은 잡음이라 기록 생략.
- `tests/hooks/run-all.sh` — 37개 케이스 스모크 테스트, 격리된 임시 메모리에서 실행.
- `tests/hooks/fixtures/dangerous/` — 7개 위험 명령 픽스처.
- `.github/workflows/hooks.yml` — push/PR마다 hook 스모크 + 문법 + JSON 검증.
- `.claude/hooks/lib/dangerous-patterns.sh` — 위험 패턴 단일 진실원천.
- `install.sh`, `Makefile` — 설치 자동화.
- `CONTRIBUTING.md`, `CHANGELOG.md` — 거버넌스 분리.

### Added — 다국어 지원
- `README.zh-CN.md` — 简体中文 번역 추가.
- `README.zh-TW.md` — 繁體中文 번역 추가.
- 4개 README 간 상호 언어 배지 링크 완성 (한국어, English, 简体中文, 繁體中文).

### Changed
- `/venom` 백업 프로세스 제거 — 백업은 `npx @cgyou/venom-init` 설치 시 자동
  수행되므로 `/venom` 흡수 단계에서는 별도 백업 없이 바로 진화.
- `record-mistake.sh` — `PostToolUseFailure` 입력 스키마를 올바르게 읽도록
  수정 (`.tool_response.error` → top-level `.error`). canonical
  `hookSpecificOutput.additionalContext` 응답 채널 사용. `is_interrupt: true`
  스킵.
- `session-start.sh` — placeholder/형식 예시(코드 펜스 안의 `## ` 헤더)를
  필터링하고 최근 N개 항목으로 cap. 동일 입력 대비 출력 약 70% 감소.
- 모든 hook 셸 스크립트의 주석·메시지를 한국어로 교체.
- `CLAUDE.md` — 살아있는 심비오트 철학 추가. 의무 작업 루프에 "진화" 단계
  추가. 부록 테이블에 55~63번 규칙 등재.
- `README.md`, `README.en.md` — quick/standard/deep 제거, 살아있는 진화 철학
  반영, 🫀 자기 진화 섹션 추가, hook 테이블에 trigger-evolution 추가.
- `.claude/README.md` — 전면 개정. 진화 관련 파일 구조 반영, 핵심 설계에
  "살아있는 심비오트"와 "자기 진화" 추가.

### Fixed
- `block-dangerous.sh`가 `lib/dangerous-patterns.sh`를 source 하도록 리팩터.

## [1.0.0] — 2026-04-07

### Added
- 초기 Venom 하네스: rules(6), skills(5), hooks(7), memory(3), settings.json,
  /venom 슬래시 명령, README.
