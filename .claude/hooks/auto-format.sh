#!/usr/bin/env bash
# Write|Edit 도구용 PostToolUse hook — 편집된 파일을 확장자에 맞는 포매터로
# 자동 정리한다. 사용 가능한 포매터가 없으면 조용히 통과한다.
# 언어 무관: 감지만 하고 설치는 절대 하지 않는다.

set -euo pipefail

INPUT="$(cat)"
FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')"

[[ -z "$FILE" || ! -f "$FILE" ]] && exit 0

have() { command -v "$1" >/dev/null 2>&1; }
# 어떤 포매터가 어떤 파일에 돌았는지 stderr로 1줄 알린다(가시성).
# stdout은 비워둔다(PostToolUse는 stdout이 컨텍스트로 들어가므로 토큰 비용 발생).
run() {
  "$@" >/dev/null 2>&1 || true
  echo "[venom auto-format] $* (file: $(basename "$FILE"))" >&2
}

case "$FILE" in
  *.py)
    if have ruff; then run ruff format "$FILE"; run ruff check --fix "$FILE"
    elif have black; then run black -q "$FILE"; fi ;;
  *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.json|*.css|*.scss|*.html|*.md|*.yml|*.yaml)
    if have prettier; then run prettier --write "$FILE"; fi ;;
  *.go)
    have gofmt && run gofmt -w "$FILE"
    have goimports && run goimports -w "$FILE" ;;
  *.rs)
    have rustfmt && run rustfmt --edition 2021 "$FILE" ;;
  *.rb)
    have rubocop && run rubocop -A "$FILE" ;;
  *.sh|*.bash)
    have shfmt && run shfmt -w "$FILE" ;;
  *.tf)
    have terraform && run terraform fmt "$FILE" ;;
esac

exit 0
