# Changelog

이 프로젝트는 [Semantic Versioning](https://semver.org/)을 따릅니다.
형식은 [Keep a Changelog](https://keepachangelog.com/)를 참고합니다.

## [2.3.0] — 2026-04-23

### Added
- **지연 진화(Deferred Evolution) 패턴 도입** — 진화 권고 타이밍을 "Stop 시점 stderr"에서
  "다음 UserPromptSubmit 시점 컨텍스트 주입"으로 이동. 네 가지 제약을 동시에 충족:
  질문 중엔 발동하지 않고, 작업이 진짜 끝난 뒤에만 뜨며, 사용자가 Claude와 함께
  바로 대응할 수 있고, 세션 맥락이 살아있는 상태에서 주입된다.
- 새 라이브러리 `.claude/hooks/lib/evolution-analyzer.sh` — `mistakes.md` 분석 로직을
  추출. Stop 훅(큐잉)과 UserPromptSubmit 훅(소비 직전 재검증) 양쪽에서 공유.
- 상태 디렉토리 `.claude/state/` — `pending-evolution` 큐 플래그용. `.gitignore`에
  등재해 저장소에는 포함되지 않으며 로컬 세션 간에만 전파.

### Changed
- **`trigger-evolution.sh` 완전 리팩터** — stderr 출력 제거. 비질문 턴에 진화
  기회가 감지되면 `.claude/state/pending-evolution` 플래그 파일에 타임스탬프만
  기록. 실제 진화 이유는 소비 시점에 재계산한다 (사용자가 그 사이 `mistakes.md`를
  정리했을 수 있는 stale 케이스 방어).
- **`inject-context.sh` 큐 소비 블록 추가** — 매 프롬프트 시 큐 존재 여부 확인,
  있으면 `mv` 기반 원자적 소비 후 재분석. 여전히 유효하면 `## 🧬 진화 큐` 섹션을
  stdout으로 출력해 Claude 컨텍스트에 주입. 지침은 "현재 요청 우선, 자연스러운
  타이밍에 진화 제안" — 현재 작업 흐름을 희생하지 않는 passive 전략.
- 진화 권고는 Claude 컨텍스트로 직접 들어가므로 Claude가 자발적으로 사용자에게
  제안할 수 있고, 사용자는 긴급도에 따라 즉시 대응/연기 결정 가능.

### Fixed
- 진화 권고 문자열의 꼬리 공백 정리 — `반복 실수 태그: #shell(3) . ` 같은
  공백 이슈 제거 (`반복 실수 태그: #shell(3). `).
- `trigger-evolution.sh`의 상태 디렉토리 생성 실패에 내성 추가 — read-only fs나
  권한 문제로 `mkdir -p` 실패해도 `exit 0`으로 조용히 스킵.

### Verified
- 7개 시나리오 스모크 테스트 전부 통과: 빈 mistakes / 기회 감지 + 큐잉 /
  질문 턴 가드 / 큐 + 유효 조건 → 주입 / 연속 프롬프트 중복 방지 /
  stale 조건 자동 무효화 + 큐 소비 / 전체 훅 `bash -n` + JSON 유효성.
- `npm test` 통과.
- 컨텍스트 주입 포맷 육안 검증: Markdown 섹션 헤더 + 감지 시각 + 사유 +
  사용자-우선 지침 형식으로 판매 상품 수준 확보.

## [2.2.0] — 2026-04-23

### Changed
- **Stop 훅 정책: HARD → SOFT 전면 전환** — 사용자 질문 턴에서 `Stop hook error:`가
  뜨며 사용자 결정을 방해하던 문제 해결. `verify-before-stop.sh`와
  `trigger-evolution.sh`의 `decision:"block"` 출력을 제거하고, 모든 경고를
  stderr 힌트로 내린다. Claude 턴 흐름은 절대 차단하지 않는다.
- **종료 시 강제 검증은 SessionEnd로 이관** — 새 훅
  `.claude/hooks/evolved/session-end-reminder.sh`가 세션이 실제로 끝날 때
  dirty/미푸시 상태를 터미널 stderr로 요약 출력. Claude Code 스펙상 SessionEnd는
  차단 불가(`reason`: clear/logout/prompt_input_exit/other)이지만, 사용자에게 직접
  보여 남은 작업을 상기시킨다.

### Added
- `is_question_stop` 강화 — 훅 입력의 신설 `last_assistant_message` 필드를
  최우선으로 사용(transcript 타이밍 이슈 회피). `AskUserQuestion` tool_use도
  transcript 파싱으로 감지해, 도구 기반 질문 턴까지 안전하게 스킵한다.
- 질문 감지 정규식 확장 — `stage할게요?`, `푸시할게요?`, `선택해 주`, `답해 주`,
  `다음 중`, `진행하시겠`, `해드릴까요`, `드려도 될까` 등 강한 질문 지표 토큰 추가.
  과거의 `$` 꼬리 앵커를 풀고 마지막 1500바이트 범위에서 토큰 매칭하도록 완화.
- `.claude/hooks/evolved/` — 자기 진화 프로토콜(55-self-evolution.md)에 따른
  신규 훅용 전용 경로. 첫 입주자: `session-end-reminder.sh`.

### Fixed
- **dirty 10개 이상일 때 강화된 경고** — `verify-before-stop.sh`가 대규모 미커밋
  변경에 대해 `⚠️` 프리픽스와 함께 더 강한 문구로 경고한다. SOFT이지만 눈에 띄도록.

### Verified
- `npm test` 통과 — 14개 훅 스크립트 전부 `bash -n` OK, `settings.json` JSON 유효.
- Stop 훅 스모크 테스트 — 질문 턴(`last_assistant_message`=질문) 완전 스킵,
  비질문 dirty 턴에서 stderr 힌트만 출력, `stop_hook_active=true` 루프 방지 동작.
- SessionEnd 훅 스모크 테스트 — `reason=clear|prompt_input_exit` 모두 exit 0,
  dirty 파일 요약이 stderr로 출력됨.
- `is_question_stop` 유닛 스모크 — 질문/비질문/빈 입력/마크다운 꼬리/도구 사용 턴
  8케이스 전부 기대값 일치.

## [2.1.1] — 2026-04-22

### Security
- **비밀 파일 stdin redirect 우회 차단** — `cat < .env` 같은 stdin redirect
  경유 비밀 파일 읽기가 v2.1.0의 차단 패턴을 통과하던 우회 경로 보강. 6개
  보조 패턴(`<` redirect 전용)을 기존 6개 쌍 뒤에 추가. 이제 모든 비밀 파일
  케이스에 대해 `cat <file`, `cat <  file`, `cat<file` 등 전부 차단.

### Fixed
- **heredoc false positive 해소** — v2.1.0 패턴의 `[^|>]*`가 `<` 문자를 허용해,
  본문에 `.env` 언급이 있는 정상적인 heredoc(예: 설치 가이드 출력)까지 차단되던
  오탐 수정. `[^|><]*`로 좁혀 heredoc 구문을 우회한 뒤, 위의 보조 `<` 패턴으로
  실제 stdin redirect 우회만 선택 차단.
- **`git push -f` 패턴 누락 수정** — 기존 `git[[:space:]]+push[[:space:]].*[[:space:]]-f(...)`
  패턴이 `-f`를 첫 인자로 받는 `git push -f` 형식을 놓치던 버그. 인자 유무와
  무관하게 매칭되도록 `(.*[[:space:]])?-f(...)`로 교체. `-f`가 다른 인자로
  이어지는 케이스(예: `origin feature-f`)는 계속 allow.

### Verified
- 회귀 스위트 확장 — 39/39 통과 (기존 14 + 비밀 파일 직접 13 + stdin redirect 6 +
  heredoc/정상 6, 멀티라인 heredoc 포함).
- `bash -n .claude/hooks/lib/dangerous-patterns.sh` OK.
- `DANGEROUS_PATTERNS` 배열 길이 29 (v2.1.0 기준 +6).

## [2.1.0] — 2026-04-21

전면 점검 세션 (ADR-0001). 보안/아키텍처/효율성/hook 안정성 4축에서 발견한
Critical 3, High 3, Medium 4, Low 4 — 합계 13개 결함 일괄 수정.

### Security
- **비밀 파일 읽기 차단 신규 (C2)** — `block-dangerous`에서
  `cat/head/tail/less/more/bat/strings/xxd/od` 류가 `.env`, `id_rsa`,
  `id_ed25519`, `.aws/credentials`, `.ssh/id_*`, `*.pem` 파일을 읽는 행동을
  Bash 경로에서 차단 (20-security 규칙과 정합). 6개 패턴 추가.
- **`scan-secrets.sh` `sk-` 패턴 엄격화 (L4)** — 기존 패턴이 `sk-learn` 같은
  무해 문자열까지 매치하던 false positive 수정.
  `(?<![A-Za-z0-9_-])sk-(?:ant-|proj-)?[A-Za-z0-9_\-]{32,}` 형태로 강화.

### Fixed
- **`git push --force-with-lease` 오차단 해소 (C1)** —
  `block-dangerous`의 `.*--force` ERE가 `--force-with-lease`까지
  잘못 차단하던 버그. `--force([[:space:]]|$)`로 엄격화.
- **`trigger-evolution.sh` UNFILLED 감지 복구 (C3)** — 실제 파일에 존재하지
  않는 `lesson:` 접두를 찾아 진화 알림이 영영 울리지 않던 결함. 패턴을
  `(Claude should fill`로 교정하여 진화 루프가 실제 동작.
- **`compact-guide` 업그레이드 경로 수정 (H1)** — `venom-init.mjs`의
  `HARNESS_SKILLS` 집합에 `compact` 오타로 실제 `compact-guide`가
  "사용자 소유"로 취급되어 업그레이드 시 갱신되지 않던 결함. 정확한
  이름으로 교정.
- **`CLAUDE.md` 부록 테이블 정합 (H2)** — 60/61/62/63 규칙 파일 행에
  "_/venom 실행 후 생성_" 주석을 달아 초기 설치 상태와 실제 존재 여부의
  괴리를 해소.
- **`session-start.sh` silent failure 제거 (M3)** — 메모리 주입 블록의
  `2>/dev/null || true`가 규칙 7 "조용한 실패 금지"를 위반. 실패 시 stderr로
  원인을 출력하도록 교체.
- **`.gitignore` 경로 정합 (M1·M2)** — `.claude/.venom-backup/`을 실제 쓰는
  `.venom-backup/`으로 교정. `.claude/settings.local.json`(개인 권한 토글)
  제외 항목 추가.
- **`mistake-recorder` / 메모리 프로토콜 정합 (M4)** — "500줄 넘으면 archive로
  옮긴다"가 50-memory-protocol의 "승급 후 삭제" 모델과 충돌. "500줄 = 진화
  대기열이 가득 찼다는 신호, evolve를 먼저 돌린다"로 정합화.
- **`HARNESS_MEMORY_DIR` 일관화 (L3)** — `record-mistake.sh`,
  `record-permission-denied.sh`, `record-stop-failure.sh`가 `.claude/memory`
  경로를 하드코딩하여 환경변수를 무시하던 불일치. env 우선 · 기본값 폴백으로 통일.
- **`inject-context.sh` `diff` 키워드 정밀화 (L2)** — 컨텍스트 주입 키워드가
  너무 넓어 false positive 발생. `git diff|diff.*봐`로 좁힘.
- **`evolved/token-saver` placeholder (L1)** — 빈 폴더 상태로 남아있던
  placeholder에 설명 SKILL.md 추가.

### Changed
- **`npm test` 스크립트 전면 개편 (H3)** — 존재하지 않는 `tests/cli/*.test.mjs`
  를 참조하여 항상 실패하던 상태를 의미 있는 검증으로 교체:
  (a) 모든 `.claude/hooks/*.sh`와 `.claude/hooks/lib/*.sh`에 대해 `bash -n`
  문법 검증, (b) `.claude/settings.json` JSON 로딩 검증.

### Verified
- 전체 hook/lib `bash -n` — 13/13 OK
- `settings.json` / `package.json` JSON 파싱 — OK
- `venom-init.mjs` `node --check` — OK
- block-dangerous 회귀 스위트 — 17/17 통과 (`--force-with-lease` 허용 + 비밀
  파일 차단 포함)
- `trigger-evolution` 스모크 — 목 `mistakes.md`로 UNFILLED 감지 확인
- `npm test` — OK

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
