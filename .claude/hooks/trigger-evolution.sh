#!/usr/bin/env bash
# Stop hook — 세션 종료 전 진화 기회를 감지한다.
#
# 정책 (v2.2.0 이후): **SOFT-only**.
#   과거에는 decision:block으로 Claude의 턴을 중단시켰지만, 이 방식은
#   사용자 질문 대기 중에도 "Stop hook error"를 찍어 UX를 방해했다.
#   이제 stderr 힌트만 출력하며 절대 차단하지 않는다.
#
# 역할: mistakes.md를 스캔하여 동일 태그의 실수가 2회 이상이거나 미기입
# 교훈 항목이 있으면 55-self-evolution.md 프로토콜에 따라 진화를 권고한다.
# verify-before-stop.sh가 "코드 검증"이라면 이 훅은 "배움 검증".
#
# 토큰 비용: 진화 기회가 없으면 출력 0. 있을 때만 간결한 권고.

set -euo pipefail

# shellcheck source=lib/stop-guard.sh
source "$(dirname "$0")/lib/stop-guard.sh"

INPUT="$(cat)"
STOP_HOOK_ACTIVE="$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')"

# 무한 루프 방지
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

# 질문 턴이면 조용히 스킵
if is_question_stop "$INPUT"; then
  exit 0
fi

REPO="${CLAUDE_PROJECT_DIR:-.}"
MISTAKES="$REPO/.claude/memory/mistakes.md"

# mistakes.md가 없거나 비어있으면 할 일 없음
[[ -f "$MISTAKES" && -s "$MISTAKES" ]] || exit 0

# 태그별 실수 횟수를 센다.
# 형식: "- 태그: #tag1 #tag2" 줄에서 태그를 추출하여 빈도 계산.
# 코드 펜스 안의 내용은 건너뛴다.
REPEATED_TAGS=$(awk '
  /^```/ { in_fence = !in_fence; next }
  !in_fence && /^- (태그|tag)/ {
    n = split($0, parts, "#")
    for (i = 2; i <= n; i++) {
      gsub(/[[:space:]]+$/, "", parts[i])
      gsub(/[[:space:]]+/, "", parts[i])
      if (parts[i] != "") tags[parts[i]]++
    }
  }
  END {
    for (t in tags) {
      if (tags[t] >= 2) printf "%s(%d) ", t, tags[t]
    }
  }
' "$MISTAKES")

# 오늘 세션에서 새로 추가된 실수 중 교훈이 아직 채워지지 않은 항목 수
UNFILLED=$(grep -c "(Claude should fill" "$MISTAKES" 2>/dev/null || echo 0)

REASONS=""
[[ -n "$REPEATED_TAGS" ]] && REASONS="${REASONS}반복 실수 태그: ${REPEATED_TAGS}. "
[[ "$UNFILLED" -gt 0 ]]  && REASONS="${REASONS}교훈 미기입 항목 ${UNFILLED}개. "

if [[ -n "$REASONS" ]]; then
  # SOFT: stderr로 힌트만. Stop 흐름을 막지 않는다.
  printf '🧬 [venom 진화 감지] %s55-self-evolution.md 프로토콜에 따라 진화를 고려하세요: 반복 실수 → 규칙/hook 강화, 미기입 교훈 → lessons.md 갱신.\n' "$REASONS" >&2
fi

exit 0
