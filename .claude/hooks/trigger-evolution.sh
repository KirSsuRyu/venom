#!/usr/bin/env bash
# Stop hook — 진화 기회를 감지해 "지연 진화 큐"에 플래그만 기록한다.
#
# 설계 (v2.3.0 Deferred Evolution 패턴):
#   감지는 Stop에서, 주입은 다음 UserPromptSubmit에서 (inject-context.sh).
#
# 왜 지연인가:
#   Stop 시점은 "작업이 진짜 끝났는지" 알 수 없다. 질문 대기일 수도, 사용자가
#   멈춘 것일 수도 있다. 반면 다음 UserPromptSubmit이 온다는 것은 이전 작업이
#   100% 종료 확정이라는 신호다. 이 시점에 Claude 컨텍스트로 진화 권고를
#   주입하면 Claude가 자연스러운 타이밍에 사용자에게 제안할 수 있다.
#
# 동작:
#   1) stop_hook_active=true → 루프 방지, 즉시 종료
#   2) is_question_stop → 질문 턴엔 큐잉하지 않음 (이중 안전장치)
#   3) mistakes.md 분석 → 진화 기회 있으면 .claude/state/pending-evolution 터치
#   4) 없으면 조용히 종료
#
# 큐 파일은 "플래그"만 저장한다 (타임스탬프). 실제 이유는 UserPromptSubmit
# 시점에 재계산한다 — 그 사이 사용자가 mistakes.md를 정리했을 수 있으므로.
#
# 차단 없음, stderr 없음, stdout 없음. 완전 조용.

set -euo pipefail

# shellcheck source=lib/stop-guard.sh
source "$(dirname "$0")/lib/stop-guard.sh"
# shellcheck source=lib/evolution-analyzer.sh
source "$(dirname "$0")/lib/evolution-analyzer.sh"

INPUT="$(cat)"
STOP_HOOK_ACTIVE="$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')"

# 루프 방지
[[ "$STOP_HOOK_ACTIVE" == "true" ]] && exit 0

# 질문 턴이면 큐잉하지 않는다 (정책: 사용자 결정 흐름 방해 금지)
if is_question_stop "$INPUT"; then
  exit 0
fi

REPO="${CLAUDE_PROJECT_DIR:-.}"
MISTAKES="$REPO/${HARNESS_MEMORY_DIR:-.claude/memory}/mistakes.md"
STATE_DIR="$REPO/.claude/state"
PENDING="$STATE_DIR/pending-evolution"

# 진화 기회가 없으면 큐잉하지 않는다 (소음 최소화)
if ! analyze_evolution_opportunity "$MISTAKES" >/dev/null 2>&1; then
  exit 0
fi

# 플래그 파일 작성 (타임스탬프만 저장. 이유는 소비 시점에 재계산).
# 상태 디렉토리 생성/쓰기 실패는 사용자 작업 흐름과 무관하므로 조용히 스킵한다.
if mkdir -p "$STATE_DIR" 2>/dev/null; then
  printf 'queued_at=%s\n' "$(date -u +%FT%TZ)" > "$PENDING" 2>/dev/null || true
fi

exit 0
