#!/usr/bin/env bash
# PostToolUseFailure hook — 도구 실패를 mistakes.md에 자동 기록한다.
# 다음 SessionStart에서 Claude가 읽고 같은 실수를 반복하지 않도록.

set -euo pipefail

INPUT="$(cat)"
TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // "unknown"')"
# PostToolUseFailure 입력 스키마: top-level `.error` 필드.
# 호환을 위해 구버전 경로(.tool_response.error)도 후순위로 시도.
ERR="$(printf '%s' "$INPUT" | jq -r '.error // .tool_response.error // .tool_response // "(no error text)"' | head -c 500)"
CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // .tool_input.file_path // .tool_input // ""' | head -c 300)"
INTERRUPT="$(printf '%s' "$INPUT" | jq -r '.is_interrupt // false')"

# 사용자 인터럽트는 실수가 아니므로 기록하지 않는다.
if [[ "$INTERRUPT" == "true" ]]; then
  exit 0
fi

MEM_DIR="${CLAUDE_PROJECT_DIR:-.}/${HARNESS_MEMORY_DIR:-.claude/memory}"
mkdir -p "$MEM_DIR"
FILE="$MEM_DIR/mistakes.md"

[[ ! -f "$FILE" ]] && {
  echo "# 실수 로그"                                                   >  "$FILE"
  echo                                                                   >> "$FILE"
  echo "자동 기록된 실패와 사용자 교정. 모든 세션 시작 시 읽힙니다." >> "$FILE"
  echo "**같은 실수를 두 번 하지 마세요.**"                            >> "$FILE"
  echo                                                                   >> "$FILE"
}

{
  echo "## $(date -u +%Y-%m-%dT%H:%M:%SZ) — $TOOL failed"
  echo "- 맥락: (Claude should fill — 어떤 작업 중이었는가)"
  echo "- 한 일: \`$(printf '%s' "$CMD" | tr '\n' ' ')\`"
  echo "- 왜 틀렸나: $(printf '%s' "$ERR" | tr '\n' ' ')"
  echo "- 옳은 접근: (Claude should fill — 다음엔 어떻게)"
  echo "- 태그: (Claude should fill — #area #tool)"
  echo
} >> "$FILE"

# PostToolUseFailure의 canonical 응답 채널: hookSpecificOutput.additionalContext
jq -n --arg msg "Failure recorded to .claude/memory/mistakes.md. Read it, diagnose the root cause, and update the 'lesson' line before retrying." \
  '{ hookSpecificOutput: { hookEventName: "PostToolUseFailure", additionalContext: $msg } }'

exit 0
