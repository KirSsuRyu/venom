#!/usr/bin/env bash
# UserPromptSubmit hook — 매 프롬프트마다 Claude 컨텍스트에 주입:
#   1) git 저장소 상태 (브랜치, dirty 파일 수) — 항상 출력
#   2) 프롬프트 키워드 기반 스킬 힌트 — 감지 시에만 1줄 추가
#   3) 지연 진화 큐 소비 (v2.3.0) — 큐 플래그 있으면 진화 권고를 주입하고 소비
#
# 토큰 비용: *매 프롬프트마다* 실행. git 상태 ~3줄 / 스킬 힌트 0~1줄 /
#   진화 권고는 큐가 쌓였고 조건이 여전히 유효할 때만 ~6줄.
#
# 주입 방식: stdout의 텍스트가 그대로 Claude의 UserPromptSubmit 컨텍스트에 들어간다
# (Claude Code 규약). 섹션 구분을 위해 Markdown 헤더 사용.

set -euo pipefail

HOOK_DIR="$(dirname "$0")"
REPO="${CLAUDE_PROJECT_DIR:-.}"

# stdin 한 번만 읽어 재사용
INPUT="$(cat 2>/dev/null || true)"

# --- 1. git 상태 주입 ---
if command -v git >/dev/null 2>&1 && git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$REPO" branch --show-current 2>/dev/null || echo "(detached)")
  dirty=$(git -C "$REPO" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  echo "## Repo state"
  echo "- branch: $branch"
  echo "- uncommitted files: $dirty"
fi

# --- 2. 스킬 힌트 (키워드 감지, 해당 시에만 1줄 출력) ---
prompt_text=""
if command -v python3 >/dev/null 2>&1 && [ -n "$INPUT" ]; then
  prompt_text=$(printf '%s' "$INPUT" | python3 -c "
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
  lower=$(printf '%s' "$prompt_text" | tr '[:upper:]' '[:lower:]')

  # 디버깅/버그 단계 — debug-loop
  if echo "$lower" | grep -qE '버그|에러|오류|왜.*안|안.*돼|실패|debug|error|broken|traceback|exception|왜.*동작|고쳐줘|안 돼|안돼'; then
    hint="debug-loop"
  # 보안 감사 — code-review (보안 모드)
  elif echo "$lower" | grep -qE '보안|취약|security|owasp|해킹|exploit|injection|xss|sqli|csrf|인증.*검토|auth.*review'; then
    hint="code-review (보안 감사 모드)"
  # 코드 리뷰 단계 — code-review
  elif echo "$lower" | grep -qE '리뷰|검토|pr.*봐|코드.*봐|git diff|diff.*봐|review|pull.request|머지 전|merge.*전|변경사항.*봐'; then
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

# --- 3. 지연 진화 큐 소비 (Deferred Evolution, v2.3.0) ---
# 큐 파일이 있다는 건 이전 Stop 시점에 진화 기회가 감지됐다는 뜻이다.
# 하지만 그 사이 사용자가 mistakes.md를 정리했을 수 있으므로,
# 주입 직전에 재분석하여 여전히 유효한 경우에만 컨텍스트에 넣는다.
# 큐 파일은 재분석 결과와 무관하게 소비(삭제)하여 중복 주입을 방지한다.
STATE_DIR="$REPO/.claude/state"
PENDING="$STATE_DIR/pending-evolution"

if [ -f "$PENDING" ]; then
  # 원자적 소비: mv로 먼저 빼낸 뒤 분석 (race condition 방어)
  CONSUMED=""
  if CONSUMED=$(mktemp "$STATE_DIR/consumed-XXXXXX" 2>/dev/null) && mv "$PENDING" "$CONSUMED" 2>/dev/null; then
    # 현재 시점 기준으로 진화 기회 재분석
    # shellcheck source=lib/evolution-analyzer.sh
    if [ -f "$HOOK_DIR/lib/evolution-analyzer.sh" ]; then
      source "$HOOK_DIR/lib/evolution-analyzer.sh"
      MISTAKES="$REPO/${HARNESS_MEMORY_DIR:-.claude/memory}/mistakes.md"
      REASONS=""
      if REASONS=$(analyze_evolution_opportunity "$MISTAKES" 2>/dev/null) && [ -n "$REASONS" ]; then
        queued_at=$(grep -E '^queued_at=' "$CONSUMED" 2>/dev/null | head -1 | cut -d= -f2- || echo "unknown")
        cat <<EOF

## 🧬 진화 큐 (venom, Deferred Evolution)
이전 작업이 종료되어 진화 기회가 감지되었습니다.
- 감지 시각: ${queued_at}
- 사유: ${REASONS}

**지침**: 현재 사용자 요청을 정상적으로 우선 처리하세요. 다만 요청 처리가
끝난 직후 또는 관련 영역을 수정하게 되는 자연스러운 타이밍에, 55-self-evolution.md
프로토콜에 따라 사용자에게 진화를 제안하세요.
- 반복 태그 → 해당 영역의 규칙 강화 또는 hook 생성
- 미기입 교훈 → lessons.md에 구체 교훈 기록

긴급도는 낮습니다. 현재 요청을 희생하면서까지 선제 질문하지는 마세요.
이 알림은 한 번만 주입되며 자동 소비되었습니다.
EOF
      fi
    fi
    # 소비 흔적 제거 (실패해도 무해 — 다음 실행 때 덮어씀)
    rm -f "$CONSUMED" 2>/dev/null || true
  fi
fi

exit 0
