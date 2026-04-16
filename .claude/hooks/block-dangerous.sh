#!/usr/bin/env bash
# Bash 도구용 PreToolUse hook — 언어/스택 무관하게 파괴적·위험한 셸 명령을
# 차단한다. 도구 입력은 stdin으로 JSON으로 들어온다.
#
# 엄격도 프로파일 (VENOM_HOOK_PROFILE 환경변수로 제어):
#   permissive — 경고만 출력, 실행은 허용 (개발 초기·실험적 작업)
#   standard   — 위험 명령 차단 (기본값, 일반 개발)
#   strict     — 차단 + 경고성 패턴(sudo, force-push 등)도 차단

set -euo pipefail

INPUT="$(cat)"
CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"

if [[ -z "$CMD" ]]; then
  exit 0
fi

# 프로파일 읽기 (기본: standard)
PROFILE="${VENOM_HOOK_PROFILE:-standard}"

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

warn() {
  # permissive 모드: stdout으로 경고만 주입하고 실행은 허용
  echo "## ⚠️ VENOM 경고 (permissive 모드)"
  echo "위험 패턴이 감지됐지만 \`VENOM_HOOK_PROFILE=permissive\` 설정으로 실행을 허용합니다."
  echo "- 명령: \`$CMD\`"
  echo "- 감지된 패턴: $1"
  echo "표준 모드로 전환하려면: \`export VENOM_HOOK_PROFILE=standard\`"
}

# 위험 패턴은 단일 소스에서 가져온다.
# shellcheck source=lib/dangerous-patterns.sh
source "$(dirname "$0")/lib/dangerous-patterns.sh"

for p in "${DANGEROUS_PATTERNS[@]}"; do
  if [[ "$CMD" =~ $p ]]; then
    if [[ "$PROFILE" == "permissive" ]]; then
      warn "$p"
      exit 0
    else
      deny "하네스가 차단함: 명령이 위험 패턴 '$p'와 일치합니다. 정말 필요하다면 사용자에게 명시적으로 요청하세요."
    fi
  fi
done

# 비밀 파일에 대한 쓰기 redirect
if [[ "$CMD" =~ $SECRET_REDIRECT_PATTERN ]]; then
  if [[ "$PROFILE" == "permissive" ]]; then
    warn "SECRET_REDIRECT"
    exit 0
  else
    deny "차단됨: 자격증명/비밀 파일에 쓰기를 거부합니다."
  fi
fi

# strict 모드 전용 추가 패턴
if [[ "$PROFILE" == "strict" ]]; then
  STRICT_PATTERNS=(
    'git[[:space:]]+push[[:space:]].*--force-with-lease'  # force-with-lease도 차단
    'chmod[[:space:]]+-R'                                  # 재귀 chmod (any)
    'chown[[:space:]]+-R'                                  # 재귀 chown
    'truncate[[:space:]]'                                  # 파일 내용 삭제
    '>[[:space:]]*/etc/'                                   # /etc/ 쓰기
  )
  for p in "${STRICT_PATTERNS[@]}"; do
    if [[ "$CMD" =~ $p ]]; then
      deny "하네스(strict 모드)가 차단함: '$p' 패턴은 strict 프로파일에서 금지됩니다."
    fi
  done
fi

exit 0
