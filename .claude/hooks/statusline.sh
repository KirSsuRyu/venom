#!/usr/bin/env bash
# statusline — 매 프롬프트 하단 한 줄에 하네스 상태를 표시한다.
#
# 입력: stdin JSON — { model, cwd, session_id, ... } 형태 (Claude Code 규약)
# 출력: 단일 줄 (ANSI 색 허용). 실패해도 빈 줄만 출력해 세션을 방해하지 않는다.
#
# 출력 형식:
#   [부모 statusline 출력] ┃ 🐍 <branch> · <dirty>⚠ · 🧬 · 📝<mistakes>
#
# 부모 statusline 체이닝:
#   ~/.claude/settings.json 에 다른 statusLine.command 가 등록돼 있으면 먼저
#   실행해 그 출력을 좌측에 붙인다. 사용자가 자신만의 statusline을 이미 쓰던
#   경우 같이 노출된다. 환경변수 VENOM_STATUSLINE_DEPTH 로 무한 재귀 방어.
#
# 비활성화:
#   VENOM_STATUSLINE_NO_CHAIN=1   → 부모 체이닝 스킵 (Venom 단독 출력)
#
# 성능 예산: 100ms 이내. 모든 git 호출은 로컬 인덱스만 사용.

set -u  # -e 는 절대 켜지 않는다 — 한 줄 실패로 statusline이 깨지면 안 됨

# 무한 재귀 방어. 부모 호출 시 export 하므로 자식 인스턴스는 즉시 알아차린다.
DEPTH="${VENOM_STATUSLINE_DEPTH:-0}"
export VENOM_STATUSLINE_DEPTH=$((DEPTH + 1))

# JSON 입력을 변수로 보존 (부모 호출에 그대로 넘기기 위함)
INPUT="$(cat 2>/dev/null || true)"

# CWD 결정 (env > stdin JSON > pwd)
CWD="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$CWD" ] && command -v jq >/dev/null 2>&1; then
  CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // .workspace.cwd // empty' 2>/dev/null || true)"
fi
[ -z "$CWD" ] && CWD="$(pwd 2>/dev/null || echo .)"

# --- 1. 부모 statusline 체이닝 ----------------------------------------
PARENT_OUT=""
if [ "$DEPTH" = "0" ] && [ -z "${VENOM_STATUSLINE_NO_CHAIN:-}" ]; then
  USER_SETTINGS="${HOME:-}/.claude/settings.json"
  if [ -n "${HOME:-}" ] && [ -f "$USER_SETTINGS" ] && command -v jq >/dev/null 2>&1; then
    PARENT_CMD="$(jq -r '.statusLine.command // empty' "$USER_SETTINGS" 2>/dev/null || true)"
    # 자기 자신을 가리키는 경로는 스킵 (이중 안전망)
    case "$PARENT_CMD" in
      *venom*statusline.sh*|*statusline.sh*venom*)
        PARENT_CMD=""
        ;;
    esac
    if [ -n "$PARENT_CMD" ]; then
      # bash -c 로 실행. stdin 으로 원본 JSON 전달. stderr 는 무음.
      PARENT_OUT="$(printf '%s' "$INPUT" \
        | bash -c "$PARENT_CMD" 2>/dev/null \
        | head -n 1 \
        || true)"
    fi
  fi
fi

# --- 2. Venom 상태 ---------------------------------------------------
OUT=""

# git 상태
if command -v git >/dev/null 2>&1 && git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$CWD" branch --show-current 2>/dev/null || true)"
  [ -z "$branch" ] && branch="?"
  dirty="$(git -C "$CWD" status --porcelain 2>/dev/null | wc -l | tr -d ' \t\n')"
  OUT="🐍 ${branch}"
  if [ -n "${dirty:-}" ] && [ "${dirty:-0}" -gt 0 ] 2>/dev/null; then
    OUT="${OUT} · ${dirty}⚠"
  fi
fi

# 진화 큐
if [ -f "$CWD/.claude/state/pending-evolution" ]; then
  [ -n "$OUT" ] && OUT="${OUT} · "
  OUT="${OUT}🧬"
fi

# mistakes 항목 수 — 코드 펜스 안의 ## 예시는 제외 (템플릿이 1로 보이던 버그 fix)
MIST="$CWD/.claude/memory/mistakes.md"
if [ -f "$MIST" ] && command -v awk >/dev/null 2>&1; then
  cnt="$(awk '
    /^```/ { in_fence = !in_fence; next }
    !in_fence && /^## / { count++ }
    END { print count+0 }
  ' "$MIST" 2>/dev/null || echo 0)"
  cnt="${cnt:-0}"
  if [ "$cnt" -gt 0 ] 2>/dev/null; then
    [ -n "$OUT" ] && OUT="${OUT} · "
    OUT="${OUT}📝${cnt}"
  fi
fi

# --- 3. 합성 출력 (항상 단일 줄) -------------------------------------
COMBINED=""
if [ -n "$PARENT_OUT" ] && [ -n "$OUT" ]; then
  COMBINED="${PARENT_OUT} ┃ ${OUT}"
elif [ -n "$PARENT_OUT" ]; then
  COMBINED="${PARENT_OUT}"
elif [ -n "$OUT" ]; then
  COMBINED="${OUT}"
fi

# 멀티라인/제어문자 방어 — 항상 단일 줄을 보장한다.
COMBINED="$(printf '%s' "$COMBINED" | tr -d '\r' | head -n 1)"

printf '%s\n' "$COMBINED"
