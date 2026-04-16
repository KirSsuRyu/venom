#!/usr/bin/env bash
# 위험 셸 명령 패턴의 단일 진실원천(single source of truth).
# block-dangerous.sh와 tests/hooks/* 모두 이 파일을 source 한다.
#
# 주의: 이것은 *런타임* 강제의 단일 소스다. settings.json의 permissions.deny는
# 권한 시스템 레이어의 추가 방어선이며 글로브 기반이라 표현력이 다르다.
# 정합성은 tests/hooks/test-pattern-coverage.sh가 검증한다.
#
# 패턴은 bash =~ 정규식으로 사용된다. 추가/삭제 시 반드시 테스트를 갱신하라.

# shellcheck disable=SC2034  # source된 곳에서 사용됨
DANGEROUS_PATTERNS=(
  'rm[[:space:]]+-rf?[[:space:]]+/'              # rm -rf /
  'rm[[:space:]]+-rf?[[:space:]]+~'              # rm -rf ~
  'rm[[:space:]]+-rf?[[:space:]]+\*'             # rm -rf *
  'rm[[:space:]]+-rf?[[:space:]]+\.'             # rm -rf .
  'mkfs(\.|[[:space:]])'                          # 파일시스템 포맷
  'dd[[:space:]]+if=.*of=/dev/'                   # 원시 디스크 쓰기
  ':\(\)\{.*\}'                                   # fork 폭탄
  'sudo[[:space:]]'                               # 모든 sudo
  'chmod[[:space:]]+-R[[:space:]]+777'            # 전 세계 쓰기 가능 재귀
  'curl[[:space:]].*\|[[:space:]]*(sh|bash|zsh)'  # curl | sh
  'wget[[:space:]].*\|[[:space:]]*(sh|bash|zsh)'  # wget | sh
  'git[[:space:]]+push[[:space:]].*--force'       # 강제 푸시
  'git[[:space:]]+push[[:space:]].*[[:space:]]-f([[:space:]]|$)'
  'git[[:space:]]+reset[[:space:]]+--hard'        # 파괴적 reset
  'git[[:space:]]+clean[[:space:]]+-fd'           # 파괴적 clean
  '--no-verify'                                   # git hook 우회
  '>[[:space:]]*/dev/sd[a-z]'                     # 원시 디스크로 redirect
)

# shellcheck disable=SC2034
SECRET_REDIRECT_PATTERN='\>[[:space:]]*(\.env|.*\.pem|.*id_rsa|.*\.aws/credentials)'
