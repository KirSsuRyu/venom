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
## 2026-04-16 — npm publish 3단계 실패 시퀀스
- 맥락: hook heredoc 버그 수정 후 npm publish 요청
- 한 일: (1) 이미 publish된 버전으로 publish 시도 → (2) dirty 상태에서 npm version patch 시도 → (3) OTP 없이 publish 시도
- 왜 틀렸나: publish 전 (a) npm 최신 배포 버전 확인, (b) git clean 상태 확인, (c) npm OTP 필요 여부 확인을 하지 않았음
- 옳은 접근: publish 전 순서: `git status` 클린 확인 → `npm version patch` → `git push` → `npm publish --otp=<코드>`
- 태그: #npm #publish #git
