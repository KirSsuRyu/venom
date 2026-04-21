#!/usr/bin/env bash
# StopFailure hook — 턴이 API 에러로 끝났을 때 흔적을 남긴다.
#
# 목적: rate_limit/billing/auth 같은 회복 가능한 에러를 mistakes.md에
# 기록하여 다음 세션에서 패턴을 인지할 수 있게 한다.
# 출력은 무시되므로(공식 문서) 파일 기록만 의미가 있다.

set -euo pipefail

INPUT="$(cat)"
ETYPE="$(printf '%s' "$INPUT" | jq -r '.error_type // "unknown"')"

# rate_limit / max_output_tokens 류는 실수가 아니라 한도 도달이므로 기록 생략 가능.
# billing/auth/invalid_request 같은 *대응이 필요한* 에러만 기록한다.
case "$ETYPE" in
  rate_limit|max_output_tokens)
    exit 0
    ;;
esac

MEM_DIR="${CLAUDE_PROJECT_DIR:-.}/${HARNESS_MEMORY_DIR:-.claude/memory}"
mkdir -p "$MEM_DIR"
FILE="$MEM_DIR/mistakes.md"

[[ ! -f "$FILE" ]] && {
  echo "# 실수 로그"                                           >  "$FILE"
  echo                                                          >> "$FILE"
}

{
  echo "## $(date -u +%Y-%m-%dT%H:%M:%SZ) — 턴 종료 실패 ($ETYPE)"
  echo "- 맥락: API 에러로 턴이 종료됨"
  echo "- 한 일: error_type=$ETYPE 에러 발생"
  echo "- 왜 틀렸나: (Claude should fill — 근본 원인)"
  echo "- 옳은 접근: 이 에러 유형이 재발하면 사용자 환경/계정 설정을 먼저 의심한다."
  echo "- 태그: #api #$ETYPE"
  echo
} >> "$FILE"

exit 0
