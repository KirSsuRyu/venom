#!/usr/bin/env bash
# Stop 훅 공용 가드 함수.
#
# is_question_stop <input_json>
#   마지막 어시스턴트 턴이 질문/승인 대기 문구로 끝나면 0(참) 반환.
#   그 경우 Stop 훅은 조용히 통과해야 한다.
#
# 왜: Claude가 유저에게 질문을 던진 뒤 Stop 이벤트가 발생하면
#   verify-before-stop / trigger-evolution 훅이 불필요하게 개입한다.
#   질문 턴에서는 검증이나 진화 권고가 의미 없으므로 스킵한다.
#
# 감지 방식: Python3으로 transcript JSONL을 파싱하여 마지막 어시스턴트
# 텍스트를 추출하고, 질문/승인 대기 패턴을 정규식으로 확인한다.
# AskUserQuestion 도구 의존 없이 평문 질문도 감지한다.

is_question_stop() {
  local input="$1"
  local transcript_path

  transcript_path="$(printf '%s' "$input" | jq -r '.transcript_path // ""')"
  [[ -z "$transcript_path" || ! -f "$transcript_path" ]] && return 1

  local last_text
  last_text=$(python3 - "$transcript_path" <<PYEOF
import sys, json

path = sys.argv[1]
last_text = ""
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
            if isinstance(content, list):
                parts = [c.get("text", "") for c in content
                         if isinstance(c, dict) and c.get("type") == "text"]
                text = " ".join(parts)
            else:
                text = str(content)
            if text.strip():
                last_text = text.strip()
except Exception:
    pass
print(last_text[-500:] if len(last_text) > 500 else last_text)
PYEOF
  )

  # 질문/승인 대기 패턴:
  #   물음표, 한국어 질문형 어미, 사용자 확인을 기다리는 문구
  printf '%s' "$last_text" | grep -qE \
    '(\?|？|할까요|하시겠어요|어떻게 하|진행할까요|확인해 주|맞나요|인가요|볼까요|드릴까요|괜찮으신가요|주시겠어요|주세요|커밋하겠습니다|실행하겠습니다|진행하겠습니다|승인하시면|확인해주시면|승인해주시면|초안입니다)[ .:]*$'
}
