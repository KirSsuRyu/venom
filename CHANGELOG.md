# Changelog

이 프로젝트는 [Semantic Versioning](https://semver.org/)을 따릅니다.
형식은 [Keep a Changelog](https://keepachangelog.com/)를 참고합니다.

## [Unreleased]

### Added
- `PermissionDenied` hook (`record-permission-denied.sh`) — 거부된 도구 호출을
  mistakes.md에 자동 기록. 다음 세션이 같은 시도를 안 하게 함(토큰 절감).
- `StopFailure` hook (`record-stop-failure.sh`) — API 에러 유형별 회고.
  `rate_limit`/`max_output_tokens`은 잡음이라 기록 생략.
- `tests/hooks/run-all.sh` — 37개 케이스 스모크 테스트, 격리된 임시 메모리에서 실행.
- `tests/hooks/fixtures/dangerous/` — 7개 위험 명령 픽스처.
- `.github/workflows/hooks.yml` — push/PR마다 hook 스모크 + 문법 + JSON 검증.
- `.claude/hooks/lib/dangerous-patterns.sh` — 위험 패턴 단일 진실원천.
- `.claude/rules/60-python.md` — 언어 부록 규칙 샘플.
- `install.sh`, `Makefile` — 설치 자동화.
- `CONTRIBUTING.md`, `CHANGELOG.md` — 거버넌스 분리.

### Changed
- `record-mistake.sh` — `PostToolUseFailure` 입력 스키마를 올바르게 읽도록
  수정 (`.tool_response.error` → top-level `.error`). canonical
  `hookSpecificOutput.additionalContext` 응답 채널 사용. `is_interrupt: true`
  스킵.
- `session-start.sh` — placeholder/형식 예시(코드 펜스 안의 `## ` 헤더)를
  필터링하고 최근 N개 항목으로 cap. 동일 입력 대비 출력 약 70% 감소.
- 모든 hook 셸 스크립트의 주석·메시지를 한국어로 교체.
- `CLAUDE.md` — Venom의 두 가지 동등한 핵심 목표(안전 + 토큰 절감) 명시.
  `TodoWrite` → `TaskCreate` 도구명 갱신.
- `README.md` — "💰 토큰 절감" 가치 제안 추가, 신규 hook 등재.

### Fixed
- `block-dangerous.sh`가 `lib/dangerous-patterns.sh`를 source 하도록 리팩터.

## [1.0.0] — 2026-04-07

### Added
- 초기 Venom 하네스: rules(6), skills(5), hooks(7), memory(3), settings.json,
  /venom 슬래시 명령, README.
