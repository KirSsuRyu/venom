#!/usr/bin/env bash
# SessionStart hook — 매 세션 시작 시 프로젝트 메모리를 컨텍스트에 주입한다.
# stdout이 Claude의 additionalContext가 된다.
#
# 토큰 절감 원칙:
#  - 빈 placeholder 파일은 건너뛴다 (헤더만 있는 파일을 통째로 주입하지 않음).
#  - mistakes.md/lessons.md/decisions.md는 "## " 로 시작하는 *실제 항목*만 추출.
#  - 가장 최근 N개 항목으로 cap (오래된 항목은 저장소에 남지만 컨텍스트엔 안 옴).
#  - 메모리 파일이 ~500줄을 넘으면 분할 권고 한 줄을 stderr로 출력.

set -euo pipefail
MEM="${CLAUDE_PROJECT_DIR:-.}/.claude/memory"

# 항목 단위 추출: "## " 헤더 기준으로 마지막 N개 섹션만 출력.
emit_recent_sections() {
  local file="$1"
  local label="$2"
  local max_sections="$3"

  [[ -f "$file" && -s "$file" ]] || return 0

  # 코드 펜스(```) 바깥의 "## " 헤더만 진짜 항목으로 본다.
  # placeholder 형식 예시가 코드 펜스 안에 들어 있어 토큰을 잡아먹는 것을 방지.
  local count
  count=$(awk '
    /^```/ { in_fence = !in_fence; next }
    !in_fence && /^## / { n++ }
    END { print n+0 }
  ' "$file")
  [[ "$count" -gt 0 ]] || return 0

  # 위생 경고: 파일이 너무 크면 stderr로만 알린다(컨텍스트 토큰 0).
  local lines
  lines=$(wc -l < "$file" | tr -d ' ')
  if [[ "$lines" -gt 500 ]]; then
    echo "[venom] $(basename "$file") is $lines lines — consider splitting (50-memory-protocol.md)" >&2
  fi

  echo "### $label"
  # 마지막 N개 "## " 섹션 추출. 코드 펜스 안의 헤더는 무시.
  awk -v max="$max_sections" '
    /^```/ {
      in_fence = !in_fence
      if (n > 0) sections[idx] = sections[idx] $0 "\n"
      next
    }
    !in_fence && /^## / {
      sections[++n] = ""
      idx = n
    }
    n > 0 { sections[idx] = sections[idx] $0 "\n" }
    END {
      start = (n > max) ? n - max + 1 : 1
      for (i = start; i <= n; i++) printf "%s", sections[i]
    }
  ' "$file"
  echo
}

{
  echo "## Project memory loaded by harness"
  echo
  emit_recent_sections "$MEM/mistakes.md"  "Recent mistakes (do NOT repeat)" 10
  emit_recent_sections "$MEM/lessons.md"   "Lessons learned"                  20
  emit_recent_sections "$MEM/decisions.md" "Architectural decisions"          10
  echo

  # 진화 상태 요약: 반복 실수 태그가 있으면 세션 시작 시 알린다.
  MISTAKES="$MEM/mistakes.md"
  if [[ -f "$MISTAKES" && -s "$MISTAKES" ]]; then
    REPEATED=$(awk '
      /^```/ { in_fence = !in_fence; next }
      !in_fence && /^- (태그|tag)/ {
        n = split($0, parts, "#")
        for (i = 2; i <= n; i++) {
          gsub(/[[:space:]]+$/, "", parts[i])
          gsub(/[[:space:]]+/, "", parts[i])
          if (parts[i] != "") tags[parts[i]]++
        }
      }
      END {
        for (t in tags) {
          if (tags[t] >= 2) printf "%s(%d) ", t, tags[t]
        }
      }
    ' "$MISTAKES")
    if [[ -n "$REPEATED" ]]; then
      echo "### ⚡ Evolution needed"
      echo "Repeated mistake tags: ${REPEATED}"
      echo "Consider strengthening rules/hooks for these areas (see 55-self-evolution.md)."
      echo
    fi
  fi

  echo "## End of project memory"
} 2>/dev/null || true

exit 0
