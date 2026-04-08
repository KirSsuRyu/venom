#!/usr/bin/env bash
# Bash 도구용 PreToolUse hook — 언어/스택 무관하게 파괴적·위험한 셸 명령을
# 차단한다. 도구 입력은 stdin으로 JSON으로 들어온다.

set -euo pipefail

INPUT="$(cat)"
CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"

if [[ -z "$CMD" ]]; then
  exit 0
fi

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# 위험 패턴은 단일 소스에서 가져온다.
# shellcheck source=lib/dangerous-patterns.sh
source "$(dirname "$0")/lib/dangerous-patterns.sh"

for p in "${DANGEROUS_PATTERNS[@]}"; do
  if [[ "$CMD" =~ $p ]]; then
    deny "하네스가 차단함: 명령이 위험 패턴 '$p'와 일치합니다. 정말 필요하다면 사용자에게 명시적으로 요청하세요."
  fi
done

# 비밀 파일에 대한 쓰기 redirect
if [[ "$CMD" =~ $SECRET_REDIRECT_PATTERN ]]; then
  deny "차단됨: 자격증명/비밀 파일에 쓰기를 거부합니다."
fi

exit 0
