# 교훈

이 코드베이스에 대한 항구적이고 일반화 가능한 사실. 짧게, 태그를 답니다.

형식: `- [#tag] <한 줄 사실> — <왜 중요한가>`

---

- [#memory #evolution] mistakes.md/lessons.md는 진화 대기열(임시)이고 decisions.md가 영구 이력이다 — 진화 완료 시 원본 항목을 삭제하지 않으면 "이미 해결된 실수"가 세션마다 컨텍스트를 낭비한다.
- [#structure #evolution] 진화로 새로 생성되는 규칙/스킬/훅은 각 폴더의 `evolved/` 서브폴더에 배치한다 — 기존 기반 파일과 명확히 분리되어 출처를 한눈에 파악할 수 있다.

<!-- 예시:
- [#timezone] 모든 시간 객체는 pendulum.now('UTC')로 만든다 — datetime.utcnow()와 비교하면 깨진다.
- [#db] User 모델 저장은 항상 UserService.save()를 거친다 — 직접 .save() 시 audit 로그가 빠진다.
-->
