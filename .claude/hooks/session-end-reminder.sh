#!/usr/bin/env bash
# SessionEnd hook — 세션이 종료될 때 마지막 점검 요약을 stderr로 출력한다.
#
# 왜 SessionEnd인가:
#   Claude Code 스펙상 SessionEnd는 "clear", "logout", "prompt_input_exit", "other"
#   중 하나의 reason으로 세션 종료를 알리며, **차단 불가능**하다.
#   정리/로깅 전용이지만, 우리는 여기에 "실제 종료 직전 리마인더"를 얹어
#   Stop 훅에서 옮겨온 HARD 검증의 심리적 공백을 메운다.
#
# 출력 규칙:
#   - stderr로만 (stdout은 Claude 세션과 무관).
#   - 무음 기본. dirty 변경/미커밋/누락된 검증이 있을 때만 요약 출력.
#   - 터미널로 전달되어 사용자가 직접 본다.
#
# 토큰 비용: 0. Claude 턴이 이미 끝난 뒤 호출되므로 컨텍스트에 주입되지 않는다.

set -euo pipefail

INPUT="$(cat 2>/dev/null || true)"
REASON="$(printf '%s' "$INPUT" | jq -r '.reason // "unknown"' 2>/dev/null || echo unknown)"

REPO="${CLAUDE_PROJECT_DIR:-.}"

# git 없으면 전체 스킵
command -v git >/dev/null 2>&1 || exit 0
git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

dirty=$(git -C "$REPO" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
unpushed=$(git -C "$REPO" log --oneline '@{upstream}..HEAD' 2>/dev/null | wc -l | tr -d ' ' || echo 0)

# 할 말이 없으면 조용히 종료 (정상 상태)
if [[ "$dirty" -eq 0 && "$unpushed" -eq 0 ]]; then
  exit 0
fi

{
  echo ""
  echo "─── 🐍 venom: SessionEnd (reason=${REASON}) ───"
  if [[ "$dirty" -gt 0 ]]; then
    echo "  • dirty 파일 ${dirty}개 — 커밋되지 않은 변경이 남아 있습니다."
    if [[ "$dirty" -ge 10 ]]; then
      echo "    ⚠️  변경 규모가 큽니다. 테스트/린트/타입체크 실행과 변경 요약을 남겼는지 다시 한 번 확인하세요."
    fi
  fi
  if [[ "$unpushed" -gt 0 ]]; then
    echo "  • 미푸시 커밋 ${unpushed}개 — 원격과 동기화되지 않았습니다."
  fi
  echo "──────────────────────────────────────────────"
} >&2

exit 0
