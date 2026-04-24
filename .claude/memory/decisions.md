# 아키텍처 결정 기록 (ADR)

이 프로젝트의 주요 기술적 결정. ADR 형식으로 짧게 기록합니다.

형식:
```
## ADR-NNNN: <제목>
- 날짜: YYYY-MM-DD
- 상태: 제안 | 채택 | ADR-MMMM으로 대체됨
- 기원: mistakes.md #태그 (N회) | lessons.md #태그 | 없음 (직접 결정)
- 맥락: <작용하는 힘들>
- 결정: <무엇을 골랐나>
- 결과: <장점과 단점>
```

> `기원`이 있는 ADR은 해당 mistakes.md/lessons.md 항목이 이미 삭제된 것이다.

---

<!-- 새 ADR을 이 줄 아래에 추가하세요. -->

## ADR-0002: 공식 Claude Code `.claude/` 스펙 전면 수용 — v2.4.0

- 날짜: 2026-04-24
- 상태: 채택
- 기원: 없음 (사용자 요청 · 공식 docs.claude.com 스펙 분석)
- 맥락:
  - 공식 Claude Code 문서(code.claude.com/docs/ko/claude-directory,
    overview)에서 Venom이 아직 지원하지 않는 1급 기능 5가지를 식별:
    `agents/`, `output-styles/`, `statusLine`, `.worktreeinclude`,
    `CLAUDE.local.md`.
  - 특히 **서브에이전트**는 "메인 대화 토큰 절감"이라는 Venom의 2대
    핵심 목표 중 하나와 정확히 일치하는 기능 — 격리 컨텍스트에서
    특화 작업을 돌리고 최종 보고만 반환하는 구조.
  - `output-styles`와 `statusLine`은 Venom의 5계명·4섹션 보고 규약을
    실시간으로 UX에 반영할 수 있는 유일한 공식 채널.
  - `.worktreeinclude`·`CLAUDE.local.md`는 메모리와 개인 설정의 경계를
    공식 스펙이 제공하는 대로 깔끔히 분리.
- 결정:
  - **5개 기능 전부 풀패키지로 v2.4.0에 탑재**한다.
  - 서브에이전트는 4종(`code-reviewer`, `debug-detective`, `test-writer`,
    `security-auditor`) — Venom의 5계명·보안·테스트·디버깅 규율과 정확히
    매핑.
  - `bin/venom-init.mjs`에 `HARNESS_AGENTS`·`HARNESS_OUTPUT_STYLES`
    Set을 신규 추가. 사용자 커스텀 파일은 업그레이드 시에도 보존되고,
    베이스라인만 덮어쓴다.
  - `.claude/rules/55-self-evolution.md`에 "서브에이전트 진화" 절을 신규
    삽입 — 에이전트 vs 스킬 선택 기준 명시.
- 결과:
  - (+) 공식 스펙 100% 준수 — 외부 플러그인·IDE 통합과 호환성 확보.
  - (+) 메인 대화 토큰 절감 — 특화 작업은 서브에이전트가 격리 실행.
  - (+) UX 개선 — statusLine으로 진화 대기/실수 카운트 실시간 가시화.
  - (+) 메모리-개인 설정 분리 — CLAUDE.local.md + .worktreeinclude로 공식
    경로 확립.
  - (−) 설치 파일 수 증가 (4 agents + 1 style + 1 statusline = 6파일).
    단, 전부 작은 파일이며 유지 비용은 미미.
  - (−) 하네스 소유 경로가 늘어 `isHarnessOwned` 분기 추가 — 향후
    오너십 분류 정책이 복잡해질 여지. 단일 클래스화 리팩터는 추후 과제로
    남김.

