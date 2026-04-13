#!/usr/bin/env bash
# PermissionDenied hook — 거부된 도구 호출을 mistakes.md에 기록한다.
#
# 목적(토큰 절감): 같은 거부가 다음 세션에서 반복되지 않도록 SessionStart가
# 다시 주입할 수 있게 흔적을 남긴다. PermissionDenied는 Claude에 직접
# 컨텍스트를 주입할 수 없으므로(공식 문서) 이 기록은 *다음 세션*에서 효과가 난다.

set -euo pipefail

INPUT="$(cat)"
TOOL="$(printf '%s' "$INPUT"   | jq -r '.tool_name // "unknown"')"
REASON="$(printf '%s' "$INPUT" | jq -r '.reason    // "(no reason)"' | head -c 300)"
CMD="$(printf '%s' "$INPUT"    | jq -r '.tool_input.command // .tool_input.file_path // .tool_input // ""' | head -c 300)"

MEM_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/memory"
mkdir -p "$MEM_DIR"
FILE="$MEM_DIR/mistakes.md"

[[ ! -f "$FILE" ]] && {
  echo "# 실수 로그"                                           >  "$FILE"
  echo                                                          >> "$FILE"
  echo "자동 기록된 실패와 거부. 모든 세션 시작 시 읽힙니다."  >> "$FILE"
  echo                                                          >> "$FILE"
}

{
  echo "## $(date -u +%Y-%m-%dT%H:%M:%SZ) — $TOOL 거부됨"
  echo "- 맥락: (Claude should fill — 어떤 작업 중이었는가)"
  echo "- 한 일: \`$(printf '%s' "$CMD" | tr '\n' ' ')\`"
  echo "- 왜 틀렸나: $(printf '%s' "$REASON" | tr '\n' ' ')"
  echo "- 옳은 접근: 같은 호출을 재시도하지 말 것. 사용자 승인 패턴이거나 권한 정책 위반."
  echo "- 태그: #permission #policy"
  echo
} >> "$FILE"

# 거부 자체를 되돌리지 않는다. retry:false 가 명시적 기본.
jq -n '{ hookSpecificOutput: { hookEventName: "PermissionDenied", retry: false } }'
exit 0
