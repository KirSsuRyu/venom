#!/usr/bin/env bash
# Stop hook — 세션 종료 전 진화 기회를 감지한다.
#
# mistakes.md를 스캔하여 동일 태그의 실수가 2회 이상이면
# Claude에게 진화를 권고한다. 이것이 Venom을 "살아있게" 만드는 심장 박동.
#
# verify-before-stop.sh와 함께 Stop 이벤트에 등록된다.
# verify가 빌드/테스트를 검증한다면, 이 hook은 "배움"을 검증한다.
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

# Claude가 유저에게 질문을 던진 턴이면 진화 권고를 스킵한다.
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

# 오늘 세션에서 새로 추가된 실수가 있는지 확인 (lesson 미기입 항목)
UNFILLED=$(grep -c "lesson:.*Claude should fill\|lesson:.*다음 턴에 채워야\|lesson:.*(Claude" "$MISTAKES" 2>/dev/null || echo 0)

# 진화 기회가 있을 때만 출력
NEEDS_EVOLUTION=false
REASONS=""

if [[ -n "$REPEATED_TAGS" ]]; then
  NEEDS_EVOLUTION=true
  REASONS="${REASONS}반복 실수 태그: ${REPEATED_TAGS}. "
fi

if [[ "$UNFILLED" -gt 0 ]]; then
  NEEDS_EVOLUTION=true
  REASONS="${REASONS}교훈 미기입 항목 ${UNFILLED}개. "
fi

if $NEEDS_EVOLUTION; then
  # Stop 훅의 유효한 형식: decision=block + reason으로 Claude에게 진화를 권고.
  # hookSpecificOutput.additionalContext는 Stop 훅 스키마에 존재하지 않음 → 검증 실패 유발.
  jq -n --arg reasons "$REASONS" '{
    decision: "block",
    reason: ("[venom 진화 감지] " + $reasons + "55-self-evolution.md 프로토콜에 따라 진화를 고려하세요: 반복 실수 → 규칙/hook 강화, 미기입 교훈 → lessons.md 갱신.")
  }'
fi

exit 0
