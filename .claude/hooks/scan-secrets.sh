#!/usr/bin/env bash
# UserPromptSubmit hook — 사용자가 메시지를 전송하기 직전 시크릿 패턴을 스캔한다.
#
# 목적: 사용자가 채팅에 API 키·토큰·개인키를 붙여넣는 경우 Claude가 이를
#        인지하고 거부하도록 컨텍스트에 경고를 주입한다.
#
# 탐지 패턴: OpenAI/Anthropic 키, GitHub 토큰, AWS 액세스 키,
#             Bearer 토큰, PEM 개인키 헤더, DB 연결 문자열(password= 포함)
#
# 주의: 이 훅은 *매 프롬프트마다* 실행된다. python3 없으면 조용히 통과.
# 탐지 시 stdout 출력이 컨텍스트에 주입되어 Claude가 처리를 거부하게 유도한다.
#
# bash 3.2 호환: $() 안 heredoc에 )가 있으면 명령 치환이 조기 종료되는 버그 회피를 위해
# Python 스크립트를 temp 파일로 분리한다.

set -euo pipefail

# python3 없으면 스킵 (조용히 통과)
command -v python3 >/dev/null 2>&1 || exit 0

# stdin에서 UserPromptSubmit JSON 읽기 후 환경변수로 전달
VENOM_PROMPT_JSON="$(cat)"
export VENOM_PROMPT_JSON

# Python 스크립트를 temp 파일에 기록 ($() 안 heredoc 회피)
_tmpscript=$(mktemp /tmp/venom-scan-XXXXXX.py)
trap 'rm -f "$_tmpscript"' EXIT

cat > "$_tmpscript" << 'PYEOF'
import sys, json, re, os

raw = os.environ.get("VENOM_PROMPT_JSON", "")
try:
    data = json.loads(raw)
    prompt = data.get("prompt", "")
except Exception:
    sys.exit(0)

if not prompt:
    sys.exit(0)

# 시크릿 패턴 목록 (패턴, 레이블)
PATTERNS = [
    (r'(?<![A-Za-z0-9_-])sk-(?:ant-|proj-)?[A-Za-z0-9_\-]{32,}', 'OpenAI / Anthropic API 키'),
    (r'ghp_[A-Za-z0-9]{36,}',                           'GitHub Personal Access Token'),
    (r'github_pat_[A-Za-z0-9_]{82}',                    'GitHub Fine-grained PAT'),
    (r'ghs_[A-Za-z0-9]{36,}',                           'GitHub Actions 시크릿'),
    (r'AKIA[0-9A-Z]{16}',                                'AWS Access Key ID'),
    (r'(?i)aws.{0,20}secret.{0,20}[=:]["\s]*[A-Za-z0-9/+=]{40}', 'AWS Secret Key'),
    (r'xox[baprs]-[0-9A-Za-z\-]{10,}',                  'Slack 토큰'),
    (r'Bearer\s+[A-Za-z0-9\-._~+/]{20,}={0,2}',         'Bearer 토큰'),
    (r'-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----', 'PEM 개인키'),
    (r'(?i)(?:password|passwd|pwd)\s*[=:]\s*\S{8,}',    'DB/서비스 비밀번호'),
    (r'(?i)(?:database_url|db_url)\s*[=:]\s*\S+:\S+@',   'DB 연결 문자열'),
    (r'AIza[0-9A-Za-z\-_]{35}',                          'Google API 키'),
    (r'(?i)private[_-]?key\s*[=:]\s*["\']?[A-Za-z0-9+/=_\-]{20,}', '개인키 값'),
]

found = []
for pattern, label in PATTERNS:
    if re.search(pattern, prompt):
        found.append(label)

if found:
    print("VENOM_SECRET_DETECTED:" + ", ".join(found))
PYEOF

result=$(python3 "$_tmpscript") || exit 0

# 탐지된 게 없으면 조용히 종료
[ -z "$result" ] && exit 0

# 탐지된 패턴 추출
detected="${result#VENOM_SECRET_DETECTED:}"

# 컨텍스트에 경고 주입
cat <<EOF
## ⛔ VENOM SECURITY ALERT — 시크릿 감지됨
사용자 메시지에서 다음 시크릿 패턴이 감지되었습니다: **${detected}**

이 메시지에 포함된 자격증명을 절대:
- 코드에 하드코딩하지 않는다
- 로그나 주석에 남기지 않는다
- 커밋 메시지에 포함하지 않는다
- 메모리 파일(.claude/memory/)에 기록하지 않는다

사용자에게 해당 값을 환경 변수 또는 시크릿 매니저로 옮길 것을 안내하고,
감지된 자격증명을 즉시 무효화(rotate)할 것을 권고하세요.
이 경고는 Venom의 보안 규칙(.claude/rules/20-security.md)에 따른 자동 조치입니다.
EOF

exit 0
