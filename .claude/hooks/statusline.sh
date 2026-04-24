#!/usr/bin/env bash
# statusline — 매 프롬프트 하단 한 줄에 하네스 상태를 표시한다.
#
# 입력: stdin JSON — { model, cwd, session_id, ... } 형태 (Claude Code 규약)
# 출력: 단일 줄 (ANSI 색 허용). 실패해도 빈 줄만 출력해 세션을 방해하지 않는다.
#
# 표시 요소 (공간 허용 시):
#   🐍 <branch> · <dirty>⚠ · 🧬 <진화 큐 개수> · <mistakes 항목 수>
#
# 성능 예산: 100ms 이내. 모든 git 호출은 로컬 인덱스만 사용.

set -u  # -e 는 제거 — 한 줄 실패로 statusline이 깨지면 안 됨

# JSON 입력 읽기 (실패해도 무방)
INPUT="$(cat 2>/dev/null || true)"
CWD="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$CWD" ] && command -v jq >/dev/null 2>&1; then
  CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // .workspace.cwd // empty' 2>/dev/null || true)"
fi
[ -z "$CWD" ] && CWD="$(pwd)"

OUT=""

# git 상태
if command -v git >/dev/null 2>&1 && git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$CWD" branch --show-current 2>/dev/null || echo "?")
  dirty=$(git -C "$CWD" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  OUT="🐍 ${branch}"
  if [ "${dirty:-0}" -gt 0 ] 2>/dev/null; then
    OUT="${OUT} · ${dirty}⚠"
  fi
fi

# 진화 큐 상태
PENDING="$CWD/.claude/state/pending-evolution"
if [ -f "$PENDING" ]; then
  [ -n "$OUT" ] && OUT="${OUT} · "
  OUT="${OUT}🧬 진화대기"
fi

# mistakes 항목 수 (얕은 카운트)
MIST="$CWD/.claude/memory/mistakes.md"
if [ -f "$MIST" ]; then
  cnt=$(grep -cE '^## ' "$MIST" 2>/dev/null | head -1)
  cnt=${cnt:-0}
  if [ "$cnt" -gt 0 ] 2>/dev/null; then
    [ -n "$OUT" ] && OUT="${OUT} · "
    OUT="${OUT}📝${cnt}"
  fi
fi

# 출력 (빈 줄이라도 항상 개행 하나)
printf '%s\n' "$OUT"
