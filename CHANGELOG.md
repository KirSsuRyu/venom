# Changelog

이 프로젝트는 [Semantic Versioning](https://semver.org/)을 따릅니다.
형식은 [Keep a Changelog](https://keepachangelog.com/)를 참고합니다.

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
