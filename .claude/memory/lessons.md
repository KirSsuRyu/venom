# 교훈

이 코드베이스에 대한 항구적이고 일반화 가능한 사실. 짧게, 태그를 답니다.

형식: `- [#tag] <한 줄 사실> — <왜 중요한가>`

---

<!-- 예시:
- [#timezone] 모든 시간 객체는 pendulum.now('UTC')로 만든다 — datetime.utcnow()와 비교하면 깨진다.
- [#db] User 모델 저장은 항상 UserService.save()를 거친다 — 직접 .save() 시 audit 로그가 빠진다.
-->

- [#npm #packaging] `package.json`의 `files` 화이트리스트로 디렉토리(예: `.claude`)를 통째로 포함시키면, 루트 `.npmignore`의 `.claude/foo.json` 패턴은 그 안쪽에 적용되지 않는다 — 제외하려면 해당 디렉토리 *내부*에 `.npmignore`를 둬야 한다. 검증: `npm pack --dry-run --json`. 실제 사례: `settings.local.json`이 의도치 않게 패키지에 포함됐던 것을 `.claude/.npmignore`로 해결.
- [#node-test] `node --test tests/cli` 처럼 디렉토리만 넘기면 Node 24+에서 모듈 미발견 에러가 난다 — 글롭(`tests/cli/*.test.mjs`)을 명시해야 한다. CI/스크립트 기본값으로 글롭을 쓸 것.
- [#hooks #stop-hook] Claude Code Stop 훅의 유효한 JSON 출력은 `{"decision":"block","reason":"..."}` 뿐이다 — `hookSpecificOutput.additionalContext` 같은 구조는 스키마에 없어 "Invalid input" 검증 실패를 유발한다. 다른 이벤트(UserPromptSubmit 등)의 출력 형식을 Stop 훅에 그대로 쓰면 안 된다.
