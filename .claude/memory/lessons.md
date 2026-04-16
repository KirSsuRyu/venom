# 교훈

이 코드베이스에 대한 항구적이고 일반화 가능한 사실. 짧게, 태그를 답니다.

형식: `- [#tag] <한 줄 사실> — <왜 중요한가>`

---

- [#npm #publish] `npm publish` 전 체크리스트: (1) `git status` 클린, (2) 버전이 이미 배포됐는지 확인, (3) OTP 준비. 순서: git clean → `npm version patch` → `git push` → `npm publish --otp=<코드>`.
- [#hooks #heredoc] `$()` 안에서 `<<'HEREDOC'` 사용 시 스크립트 안에 `'`가 있으면 bash가 heredoc 종료로 오인한다. Python 코드에 `$`가 없으면 `<<HEREDOC`(비인용)으로 통일.
- [#hooks #chmod] git clone 후 `.claude/hooks/` 하위 `.sh` 파일의 실행 비트가 손실될 수 있다 — `chmod +x` 없이는 Permission denied로 Stop hook이 실패함. 저장소를 직접 clone한 경우 `chmod +x .claude/hooks/**/*.sh .claude/hooks/lib/*.sh` 수동 실행 필요.

<!-- 예시:
- [#timezone] 모든 시간 객체는 pendulum.now('UTC')로 만든다 — datetime.utcnow()와 비교하면 깨진다.
- [#db] User 모델 저장은 항상 UserService.save()를 거친다 — 직접 .save() 시 audit 로그가 빠진다.
-->
