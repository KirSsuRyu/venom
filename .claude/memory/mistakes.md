# 실수 로그

자동 기록된 실패와 사용자 교정. 모든 세션 시작 시 읽힙니다.
**같은 실수를 두 번 하지 마세요.**

형식:
```
## YYYY-MM-DDTHH:MM:SSZ — <한 줄 제목>
- 맥락:
- 한 일:
- 왜 틀렸나:
- 옳은 접근:
- 태그: #area #language #tool
```

---

<!-- 새 항목을 이 줄 아래에 추가하세요. 가장 최근 항목이 위로 오게 합니다. -->
## 2026-04-16T01:30:35Z — Bash failed
- 맥락: (Claude should fill — 어떤 작업 중이었는가)
- 한 일: `npm publish --access public 2>&1`
- 왜 틀렸나: Exit code 1 npm notice npm notice 📦  @cgyou/venom-init@2.0.9 npm notice Tarball Contents npm notice 24.5kB .claude/commands/venom.md npm notice 1.4kB .claude/hooks/auto-format.sh npm notice 2.8kB .claude/hooks/block-dangerous.sh npm notice 2.6kB .claude/hooks/inject-context.sh npm notice 1.9kB .claude/hooks/lib/dangerous-patterns.sh npm notice 2.5kB .claude/hooks/lib/stop-guard.sh npm notice 1.4kB .claude/hooks/protect-paths.sh npm notice 2.2kB .claude/hooks/record-mistake.sh npm notice 1.8kB
- 옳은 접근: (Claude should fill — 다음엔 어떻게)
- 태그: (Claude should fill — #area #tool)

## 2026-04-16T01:30:49Z — Bash failed
- 맥락: (Claude should fill — 어떤 작업 중이었는가)
- 한 일: `npm version patch && npm publish --access public 2>&1`
- 왜 틀렸나: Exit code 1 npm error Git working directory not clean. npm error A complete log of this run can be found in: /Users/foodtech/.npm/_logs/2026-04-16T01_30_49_311Z-debug-0.log
- 옳은 접근: (Claude should fill — 다음엔 어떻게)
- 태그: (Claude should fill — #area #tool)

