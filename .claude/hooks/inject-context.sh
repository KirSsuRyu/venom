#!/usr/bin/env bash
# UserPromptSubmit hook — 매 프롬프트마다:
#   1) git 저장소 상태 (브랜치, dirty 파일 수) — 항상 출력
#   2) 프롬프트 키워드 기반 스킬 힌트 — 감지 시에만 1줄 추가
#
# 토큰 비용 주의: *매 프롬프트마다* 실행됨.
# git 상태: 항상 ~3줄 / 스킬 힌트: 키워드 감지 시에만 1줄 추가.

set -euo pipefail

# --- 1. git 상태 주입 ---
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null || echo "(detached)")
  dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  echo "## Repo state"
  echo "- branch: $branch"
  echo "- uncommitted files: $dirty"
fi

# --- 2. 스킬 힌트 (키워드 감지, 해당 시에만 1줄 출력) ---
# stdin에서 UserPromptSubmit JSON을 읽어 prompt 필드를 추출한다.
# python3이 없거나 파싱 실패 시 힌트 없이 조용히 종료.
prompt_text=""
if command -v python3 >/dev/null 2>&1; then
  prompt_text=$(python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('prompt', ''))
except Exception:
    pass
" 2>/dev/null || echo "")
fi

hint=""
if [ -n "$prompt_text" ]; then
  lower=$(echo "$prompt_text" | tr '[:upper:]' '[:lower:]')

  # 디버깅/버그 단계 — debug-loop
  if echo "$lower" | grep -qE '버그|에러|오류|왜.*안|안.*돼|실패|debug|error|broken|traceback|exception|왜.*동작|고쳐줘|안 돼|안돼'; then
    hint="debug-loop"
  # 보안 감사 — code-review (보안 모드) — review보다 먼저 검사
  elif echo "$lower" | grep -qE '보안|취약|security|owasp|해킹|exploit|injection|xss|sqli|csrf|인증.*검토|auth.*review'; then
    hint="code-review (보안 감사 모드)"
  # 코드 리뷰 단계 — code-review
  elif echo "$lower" | grep -qE '리뷰|검토|pr.*봐|코드.*봐|diff|review|pull.request|머지 전|merge.*전|변경사항.*봐'; then
    hint="code-review"
  # 회고 단계 — retro
  elif echo "$lower" | grep -qE '회고|retro|이번 주.*정리|뭘 했|무엇을 했|한 주|retrospective|지난.*정리'; then
    hint="retro"
  # git 작업 — git-workflow
  elif echo "$lower" | grep -qE '커밋해|푸시해|브랜치.*만들|pr.*만들|commit|push|pull.request.*만들|스테이지|stage'; then
    hint="git-workflow"
  # 테스트 — test-runner
  elif echo "$lower" | grep -qE '테스트.*돌려|테스트.*실행|test.*run|커버리지|coverage|테스트.*해줘'; then
    hint="test-runner"
  fi
fi

if [ -n "$hint" ]; then
  echo "- 💡 추천 스킬: \`$hint\`"
fi

exit 0
