#!/usr/bin/env bash
# 진화 기회 분석기 — mistakes.md를 스캔해 진화 트리거 조건을 판정한다.
#
# analyze_evolution_opportunity <mistakes_md_path>
#   stdout: 비어있지 않으면 진화 이유 문자열 (조건 미달 시 빈 줄)
#   exit:   0=기회 있음, 1=없음
#
# 트리거 조건 (55-self-evolution.md 프로토콜):
#   1) 동일 태그의 실수가 2회 이상 반복 → 규칙/훅 강화 신호
#   2) 교훈 미기입 항목 존재 → lessons.md 갱신 신호
#
# Stop 훅(trigger-evolution.sh)과 UserPromptSubmit 훅(inject-context.sh) 양쪽에서
# 동일 로직을 써야 정합성이 보장된다. Stop에서 "기회 있음"을 플래그하고,
# UserPromptSubmit에서 소비 직전에 다시 한 번 검증하여 stale 알림을 방지한다.

analyze_evolution_opportunity() {
  local mistakes="${1:-}"
  [[ -n "$mistakes" && -f "$mistakes" && -s "$mistakes" ]] || return 1

  local repeated_tags unfilled reasons=""

  # 태그별 실수 횟수 집계. 형식: "- 태그: #tag1 #tag2"
  # 코드 펜스 안은 건너뛴다 (예시 블록의 가짜 태그 무시).
  repeated_tags=$(awk '
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
        if (tags[t] >= 2) printf "#%s(%d) ", t, tags[t]
      }
    }
  ' "$mistakes")

  # 교훈 미기입 항목 수 (record-mistake.sh의 플레이스홀더 카운트)
  unfilled=$(grep -c "(Claude should fill" "$mistakes" 2>/dev/null || echo 0)
  # grep -c가 "0\n" 같은 꼬리를 뱉을 수 있어 정규화
  unfilled=$(printf '%s' "$unfilled" | tr -dc '0-9')
  [[ -z "$unfilled" ]] && unfilled=0

  # 태그 목록 꼬리 공백 제거 (awk 포맷의 trailing " " 흡수)
  repeated_tags="${repeated_tags% }"

  [[ -n "$repeated_tags" ]] && reasons="${reasons}반복 실수 태그: ${repeated_tags}. "
  [[ "$unfilled" -gt 0 ]]   && reasons="${reasons}교훈 미기입 항목 ${unfilled}개. "

  if [[ -n "$reasons" ]]; then
    printf '%s\n' "$reasons"
    return 0
  fi
  return 1
}
