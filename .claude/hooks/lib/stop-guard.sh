#!/usr/bin/env bash
# Stop 훅 공용 가드 함수.
#
# is_question_stop <input_json>
#   마지막 어시스턴트 턴이 질문/승인 대기 상태로 보이면 0(참) 반환.
#   그 경우 Stop 훅은 조용히 통과해야 한다.
#
# 왜: Claude가 유저에게 질문을 던진 뒤 Stop 이벤트가 발생하면
#   verify-before-stop / trigger-evolution 훅이 불필요하게 개입해
#   사용자 결정을 방해한다. 질문 턴에서는 검증/진화 권고가 의미 없으므로 스킵한다.
#
# 감지 소스 (우선순위):
#   1) 훅 입력 JSON의 last_assistant_message 필드 — Claude Code 최신 스키마에서
#      어시스턴트의 최종 텍스트를 직접 전달한다. 가장 신뢰.
#   2) transcript_path JSONL 파싱 — 마지막 어시스턴트 턴의 텍스트 꼬리 및
#      AskUserQuestion tool_use 사용 여부. (구 스키마 / 폴백)
#
# 판정:
#   - 마지막 턴에 AskUserQuestion 도구 사용 → 무조건 질문 턴 확정.
#   - 텍스트 꼬리에 질문/승인 대기 패턴 매칭 → 질문 턴으로 간주.
#
# bash 3.2 호환: $() 안 heredoc에 )가 있으면 명령 치환이 조기 종료되는 버그 회피를 위해
# Python 스크립트를 temp 파일로 분리한다.

is_question_stop() {
  local input="$1"
  local last_text=""
  local askuq="false"

  # 1) 최우선: 훅 입력의 last_assistant_message 필드
  last_text="$(printf '%s' "$input" | jq -r '.last_assistant_message // ""' 2>/dev/null || true)"

  # 2) transcript 파싱 — AskUserQuestion tool_use 감지(항상) + 폴백 텍스트(필요시)
  local transcript_path
  transcript_path="$(printf '%s' "$input" | jq -r '.transcript_path // ""' 2>/dev/null || true)"

  if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    local _tmpscript
    _tmpscript=$(mktemp /tmp/venom-stopguard-XXXXXX.py)
    # shellcheck disable=SC2064
    trap "rm -f '$_tmpscript'" RETURN

    cat > "$_tmpscript" << 'PYEOF'
import sys, json

path = sys.argv[1]
last_text = ""
askuq = False
try:
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            role = obj.get("role") or (obj.get("message") or {}).get("role", "")
            if role != "assistant":
                continue
            content = obj.get("content") or (obj.get("message") or {}).get("content", "")
            turn_text = ""
            turn_askuq = False
            if isinstance(content, list):
                for c in content:
                    if not isinstance(c, dict):
                        continue
                    t = c.get("type", "")
                    if t == "text":
                        turn_text += (c.get("text", "") or "")
                    elif t == "tool_use":
                        if (c.get("name", "") or "") == "AskUserQuestion":
                            turn_askuq = True
            else:
                turn_text = str(content)
            # 텍스트든 도구든 둘 중 하나라도 있으면 "마지막 어시스턴트 턴"으로 갱신
            if turn_text.strip() or turn_askuq:
                last_text = turn_text.strip()
                askuq = turn_askuq
except Exception:
    pass
# 첫 줄: ASKUQ/NOASK 플래그. 둘째 줄부터: 텍스트 꼬리 (최대 1500자)
print("ASKUQ" if askuq else "NOASK")
tail = last_text[-1500:] if len(last_text) > 1500 else last_text
print(tail)
PYEOF

    local _out
    _out="$(python3 "$_tmpscript" "$transcript_path" 2>/dev/null || true)"
    if [[ -n "$_out" ]]; then
      local _flag
      _flag="$(printf '%s' "$_out" | head -n1)"
      [[ "$_flag" == "ASKUQ" ]] && askuq="true"
      # hook input에 last_assistant_message가 없었다면 transcript 꼬리로 대체
      if [[ -z "$last_text" ]]; then
        last_text="$(printf '%s' "$_out" | tail -n +2)"
      fi
    fi
  fi

  # AskUserQuestion 도구가 사용된 턴이면 질문 턴 확정
  if [[ "$askuq" == "true" ]]; then
    return 0
  fi

  [[ -z "$last_text" ]] && return 1

  # 마지막 꼬리(약 1500바이트)에서 질문/승인 대기 패턴 탐지.
  # 과거엔 `$` 꼬리 앵커를 썼지만, 마크다운 코드블록/번호 목록이 뒤에 붙는 질문도 많아
  # 앵커 없이 "질문 지표" 토큰만 찾는다. 토큰은 의도적으로 강한 신호만 포함.
  printf '%s' "$last_text" \
    | tail -c 1500 \
    | grep -qE \
      '(\?|？|할까요|하시겠어요|어떻게 하|진행할까요|확인해 주|맞나요|인가요|볼까요|드릴까요|드려도 될까|괜찮으신가요|주시겠어요|알려주세요|선택해 주|선택하세요|원하시는|답해 주|다음 중|진행하시겠|계속할까|계속하시|원하십니|stage할게요|커밋할게요|푸시할게요|실행할게요|진행할게요|초안입니다|승인하시|확인해주시면|해드릴까요)'
}
