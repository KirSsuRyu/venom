#!/usr/bin/env bash
# Stop hook — Claude가 턴을 끝내기 직전 마지막 검증 게이트.
#
# 3단계 검증:
#   [HARD] 1단계 — 코드 검증: dirty 상태 + 빌드 매니페스트 존재 시 테스트 요구 (차단)
#   [SOFT] 2단계 — 메모리 점검: 새 실수/교훈을 기록할 기회를 놓치지 않도록 힌트
#   [SOFT] 3단계 — 문서 동기화: 최근 feat: 커밋이 있으면 문서 확인 권고
#
# 통과 조건 (어느 하나라도):
#   - 깨끗한 작업 디렉토리 (변경 없음)
#   - 빌드 매니페스트 없음 (테스트할 게 없는 프로젝트)
#   - stop_hook_active=true (이미 한 번 차단했음 → 무한 루프 방지)
#
# 토큰 비용 주의: 이 hook은 매 턴 종료마다 실행된다.
#   HARD 차단: JSON 블록 출력 / SOFT 힌트: 짧은 텍스트만 출력

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

# git이 없으면 전체 스킵
if ! command -v git >/dev/null 2>&1 || ! git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

dirty=$(git -C "$REPO" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

# ──────────────────────────────────────────────
# [HARD] 1단계 — 코드 검증
# ──────────────────────────────────────────────
if [[ "$dirty" -gt 0 ]]; then
  has_tests=false
  for marker in package.json pyproject.toml Cargo.toml go.mod Gemfile pom.xml build.gradle; do
    [[ -f "$REPO/$marker" ]] && has_tests=true && break
  done

  if $has_tests; then
    jq -n '{
      decision: "block",
      reason: "하네스가 종료를 차단함 [1/3 코드 검증]: 빌드/테스트 시스템이 있는 프로젝트에 커밋되지 않은 변경이 있습니다. 끝내기 전에 (1) 프로젝트의 테스트/린트/타입체크 명령을 실행하고, (2) 무엇을 바꿨고 무엇을 검증했는지 요약하고, (3) 항구적으로 배운 것이 있다면 .claude/memory/lessons.md를 갱신하세요. 그 다음 종료해도 됩니다."
    }'
    exit 0
  fi
fi

# ──────────────────────────────────────────────
# [SOFT] 2단계 — 메모리 점검 힌트
# 최근 1시간 이내에 mistakes.md가 갱신됐으면 lessons.md 기록 권고
# ──────────────────────────────────────────────
MEMORY_DIR="${REPO}/${HARNESS_MEMORY_DIR:-.claude/memory}"
if [[ -f "${MEMORY_DIR}/mistakes.md" ]]; then
  # find -mmin +0 -mmin -60 = 최근 60분 이내 수정된 파일
  if find "${MEMORY_DIR}/mistakes.md" -mmin -60 2>/dev/null | grep -q .; then
    echo "💡 [2/3 메모리 점검] 최근 mistakes.md가 갱신됐습니다. 이번 작업에서 배운 것을 lessons.md에도 기록했는지 확인하세요."
  fi
fi

# ──────────────────────────────────────────────
# [SOFT] 3단계 — 문서 동기화 힌트
# 최근 3개 커밋 중 feat: 타입이 있으면 문서 확인 권고
# ──────────────────────────────────────────────
recent_feat=$(git -C "$REPO" log --oneline -3 --no-merges 2>/dev/null | grep -c '^[a-f0-9]* feat:' || true)
if [[ "$recent_feat" -gt 0 ]]; then
  echo "💡 [3/3 문서 동기화] 최근 feat: 커밋이 있습니다. README, CHANGELOG 등 사용자 노출 문서가 코드 변경을 반영하는지 확인하세요. (git-workflow 스킬의 '문서 동기화 체크' 참고)"
fi

exit 0
