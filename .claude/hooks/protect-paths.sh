#!/usr/bin/env bash
# Write|Edit 도구용 PreToolUse hook — 보호 경로(비밀, 락파일, 생성물,
# OS 디렉토리)에 대한 쓰기를 거부한다.

set -euo pipefail

INPUT="$(cat)"
PATH_ARG="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')"

if [[ -z "$PATH_ARG" ]]; then
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

case "$PATH_ARG" in
  /etc/*|/usr/*|/bin/*|/sbin/*|/boot/*|/sys/*|/proc/*)
    deny "차단됨: 시스템 경로 '$PATH_ARG'에 쓰기를 거부합니다." ;;
  */.git/*)
    deny "차단됨: .git/ 내부에 쓰기를 거부합니다. 대신 git 명령을 사용하세요." ;;
  */.env|*/.env.*|*/id_rsa|*/id_ed25519|*/.aws/credentials|*/.ssh/*)
    deny "차단됨: 비밀/자격증명 파일에 쓰기를 거부합니다." ;;
  */node_modules/*|*/vendor/*|*/.venv/*|*/dist/*|*/build/*|*/.next/*|*/target/*)
    deny "차단됨: 생성물/의존성 디렉토리 '$PATH_ARG'에 쓰기를 거부합니다. 소스 파일을 편집하세요." ;;
  *package-lock.json|*yarn.lock|*pnpm-lock.yaml|*Cargo.lock|*poetry.lock|*Pipfile.lock|*go.sum)
    deny "차단됨: 락파일 '$PATH_ARG'를 손으로 편집하는 것을 거부합니다. 패키지 매니저를 사용하세요." ;;
esac

exit 0
