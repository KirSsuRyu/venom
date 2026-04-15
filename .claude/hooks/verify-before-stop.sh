#!/usr/bin/env bash
# Stop hook — Claude가 턴을 끝내기 직전 마지막 검증 게이트.
#
# 차단 조건 (둘 다 만족할 때만):
#   1) git이 존재하고 작업 디렉토리가 dirty(커밋되지 않은 변경 있음)
#   2) 프로젝트 루트에 알려진 빌드/테스트 매니페스트가 존재
#      (package.json, pyproject.toml, Cargo.toml, go.mod, Gemfile, pom.xml, build.gradle)
#
# 통과 조건 (어느 하나라도):
#   - 깨끗한 작업 디렉토리 (변경 없음)
#   - 빌드 매니페스트 없음 (테스트할 게 없는 프로젝트)
#   - stop_hook_active=true (이미 한 번 차단했음 → 무한 루프 방지)
#
# 토큰 비용 주의: 이 hook은 매 턴 종료마다 실행된다. JSON 출력은 차단 시에만.

set -euo pipefail

# shellcheck source=lib/stop-guard.sh
source "$(dirname "$0")/lib/stop-guard.sh"

INPUT="$(cat)"
STOP_HOOK_ACTIVE="$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')"

# 무한 루프 방지: 첫 번째 시도에만 개입한다.
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

# Claude가 유저에게 질문을 던진 턴이면 검증을 스킵한다.
if is_question_stop "$INPUT"; then
  exit 0
fi

REPO="${CLAUDE_PROJECT_DIR:-.}"

# 커밋되지 않은 변경이 있고 프로젝트에 알려진 빌드/테스트 매니페스트가 있으면
# 종료 선언 전 검증을 권한다.
if command -v git >/dev/null 2>&1 && git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  dirty=$(git -C "$REPO" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$dirty" -gt 0 ]]; then
    has_tests=false
    for marker in package.json pyproject.toml Cargo.toml go.mod Gemfile pom.xml build.gradle; do
      [[ -f "$REPO/$marker" ]] && has_tests=true && break
    done

    if $has_tests; then
      jq -n '{
        decision: "block",
        reason: "하네스가 종료를 차단함: 빌드/테스트 시스템이 있는 프로젝트에 커밋되지 않은 변경이 있습니다. 끝내기 전에 (1) 프로젝트의 테스트/린트/타입체크 명령을 실행하고, (2) 무엇을 바꿨고 무엇을 검증했는지 요약하고, (3) 항구적으로 배운 것이 있다면 .claude/memory/lessons.md를 갱신하세요. 그 다음 종료해도 됩니다."
      }'
      exit 0
    fi
  fi
fi

exit 0
