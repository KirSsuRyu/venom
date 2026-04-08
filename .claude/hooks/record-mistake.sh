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

MEM_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/memory"
mkdir -p "$MEM_DIR"
FILE="$MEM_DIR/mistakes.md"

[[ ! -f "$FILE" ]] && {
  echo "# Mistakes Log"            >  "$FILE"
  echo                              >> "$FILE"
  echo "Auto-recorded failures. Read on every session start." >> "$FILE"
  echo                              >> "$FILE"
}

{
  echo "## $(date -u +%Y-%m-%dT%H:%M:%SZ) — $TOOL failed"
  echo "- input: \`$(printf '%s' "$CMD" | tr '\n' ' ')\`"
  echo "- error: $(printf '%s' "$ERR" | tr '\n' ' ')"
  echo "- lesson: (Claude should fill this in next turn)"
  echo
} >> "$FILE"

# PostToolUseFailure의 canonical 응답 채널: hookSpecificOutput.additionalContext
jq -n --arg msg "Failure recorded to .claude/memory/mistakes.md. Read it, diagnose the root cause, and update the 'lesson' line before retrying." \
  '{ hookSpecificOutput: { hookEventName: "PostToolUseFailure", additionalContext: $msg } }'

exit 0
