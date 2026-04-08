#!/usr/bin/env bash
# UserPromptSubmit hook — 매 프롬프트마다 가벼운 저장소 상태를 주입하여
# Claude가 현재 브랜치/dirty 상태를 항상 알 수 있게 한다.
#
# 토큰 비용 주의: 이 hook은 *매 프롬프트마다* 컨텍스트에 들어간다.
# 의도적으로 작게 유지한다(현재 약 3줄).

set -euo pipefail

if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null || echo "(detached)")
  dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  echo "## Repo state"
  echo "- branch: $branch"
  echo "- uncommitted files: $dirty"
fi

exit 0
