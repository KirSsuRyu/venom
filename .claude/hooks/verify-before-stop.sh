#!/usr/bin/env bash
# Stop hook — Claude가 턴을 끝내기 직전 마지막 점검 게이트.
#
# 정책 (v2.2.0 이후): **SOFT-only**.
#   - 과거 HARD 차단 방식은 사용자 질문 턴에서도 간헐적으로 발동되어
#     사용자 결정을 방해했다. 실제 "종료" 강제 검증은 SessionEnd 훅으로 이관되었다.
#   - 이 훅은 이제 stderr 힌트만 출력하고, 절대 차단하지 않는다.
#
# 3단계 힌트 (모두 SOFT / stderr):
#   [1/3 코드 검증] dirty가 많으면 테스트/린트 실행을 권고
#   [2/3 메모리]    최근 mistakes.md가 갱신됐으면 lessons.md 기록 권고
#   [3/3 문서]      최근 feat: 커밋이 있으면 문서 확인 권고
#
# 통과 조건 (완전 스킵):
#   - stop_hook_active=true (무한 루프 방지)
#   - is_question_stop (사용자에게 질문한 턴)
#
# 토큰 비용: 모든 출력은 stderr 단문. 진짜 할 말이 있을 때만 출력.

set -euo pipefail

# shellcheck source=lib/stop-guard.sh
source "$(dirname "$0")/lib/stop-guard.sh"

INPUT="$(cat)"
STOP_HOOK_ACTIVE="$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')"

# 무한 루프 방지: 첫 번째 시도에만 개입한다.
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

# Claude가 유저에게 질문을 던진 턴이면 힌트도 내지 않는다 (사용자 시야 방해 최소화).
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
# [SOFT] 1/3 — 코드 검증 힌트
#   dirty 파일이 많을수록 더 강하게 경고한다.
# ──────────────────────────────────────────────
if [[ "$dirty" -gt 0 ]]; then
  has_tests=false
  for marker in package.json pyproject.toml Cargo.toml go.mod Gemfile pom.xml build.gradle; do
    [[ -f "$REPO/$marker" ]] && has_tests=true && break
  done

  if $has_tests; then
    if [[ "$dirty" -ge 10 ]]; then
      printf '⚠️  [1/3 코드 검증] dirty 파일이 %d개 있습니다. 종료 전에 테스트/린트/타입체크를 반드시 실행하고, 변경 범위와 검증 결과를 요약하세요. (대규모 변경일수록 회귀 위험이 큽니다)\n' "$dirty" >&2
    else
      printf '💡 [1/3 코드 검증] dirty 파일 %d개. 끝내기 전에 프로젝트 테스트/린트를 실행하고 변경 요약을 남기세요.\n' "$dirty" >&2
    fi
  fi
fi

# ──────────────────────────────────────────────
# [SOFT] 2/3 — 메모리 점검 힌트
# 최근 1시간 이내에 mistakes.md가 갱신됐으면 lessons.md 기록 권고
# ──────────────────────────────────────────────
MEMORY_DIR="${REPO}/${HARNESS_MEMORY_DIR:-.claude/memory}"
if [[ -f "${MEMORY_DIR}/mistakes.md" ]]; then
  if find "${MEMORY_DIR}/mistakes.md" -mmin -60 2>/dev/null | grep -q .; then
    echo "💡 [2/3 메모리 점검] 최근 mistakes.md가 갱신됐습니다. 이번 작업에서 배운 것을 lessons.md에도 기록했는지 확인하세요." >&2
  fi
fi

# ──────────────────────────────────────────────
# [SOFT] 3/3 — 문서 동기화 힌트
# 최근 3개 커밋 중 feat: 타입이 있으면 문서 확인 권고
# ──────────────────────────────────────────────
recent_feat=$(git -C "$REPO" log --oneline -3 --no-merges 2>/dev/null | grep -c '^[a-f0-9]* feat:' || true)
if [[ "$recent_feat" -gt 0 ]]; then
  echo "💡 [3/3 문서 동기화] 최근 feat: 커밋이 있습니다. README, CHANGELOG 등 사용자 노출 문서가 코드 변경을 반영하는지 확인하세요. (git-workflow 스킬의 '문서 동기화 체크' 참고)" >&2
fi

exit 0
