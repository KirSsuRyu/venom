# Venom에 기여하기

기여는 모두 환영입니다. 이 문서는 Venom 저장소 *자체*에 변경을 제출할 때
따를 절차를 정리합니다.

## 시작하기

```bash
git clone https://github.com/KirSsuRyu/venom.git
cd venom
make test    # 37 통과를 보장
make lint    # bash 문법 + JSON 유효성
```

테스트는 의존성이 `bash`, `jq`, `python3` 셋뿐입니다.

## 무엇을 환영하는가

- 🐛 **버그 리포트** — hook 오작동, 잘못된 차단, 누락된 위험 패턴
- 💡 **신규 hook/skill/rule 제안** — 다른 프로젝트에서 검증된 패턴이라면
  이 저장소에 일반화해서 PR
- 🌍 **언어/스택 커버리지 확장** — `auto-format.sh`에 새 포매터, `test-writer`
  에이전트에 새 테스트 러너, `venom.md`에 새 매니페스트 파일 인식 추가
- 🧬 **프로젝트별 진화 레시피** — 특정 프레임워크(Next.js, FastAPI, Spring,
  Rails 등)에 특화된 진화 레시피
- 🌐 **번역** — 현재 한국어 우선, 영어는 `README.en.md`
- 📚 **사용 사례·후기** — 잘못 차단된 사례, 잘 잡아낸 사고 모두 좋습니다

## PR 절차

1. **이슈를 먼저 열기.** 큰 변경은 사전 합의가 가장 빠릅니다.
2. **한 PR에 한 변경.** 제목에 "그리고"가 들어간다면 분리하세요.
3. **테스트 추가.** 신규 hook/패턴은 `tests/hooks/run-all.sh`에 케이스 추가.
   위험 패턴이라면 `tests/hooks/fixtures/dangerous/`에 픽스처 파일 분리
   (셸 hook이 명령줄 문자열까지 차단하므로 인라인 stdin은 동작하지 않음).
4. **언어 종속성 명시.** Venom의 기본 가치는 *언어 무관*입니다. 특정 스택에
   종속되는 변경은 `.claude/rules/60-<lang>.md`로 격리하세요.
5. **안전 규칙 *느슨하게* 만드는 변경은 보수적으로** 검토합니다. 더 *조이는*
   변경은 환영합니다. `00-core.md`의 절대 규칙은 사용자 합의 없이 풀지 않습니다.
6. **커밋 메시지**: conventional commits (`feat:`, `fix:`, `docs:`,
   `refactor:`, `test:`, `chore:`).

## 안전 점검 (PR 머지 전)

- [ ] `make test` 통과
- [ ] `make lint` 통과
- [ ] 신규 hook은 `chmod +x` 실행 권한 부여
- [ ] 신규 hook은 `.claude/settings.json`의 적절한 이벤트 배열에 등록
- [ ] 비밀/PII가 변경에 포함되지 않음
- [ ] 토큰 절감 목적과 충돌하지 않음 (SessionStart/UserPromptSubmit hook을
      추가/확장한다면 그 비용을 PR 설명에 정당화)

## 행동 강령

[Contributor Covenant](https://www.contributor-covenant.org/)를 따릅니다.
서로 존중하고, 코드와 사람을 분리해서 이야기하고, 새로운 사람을 환대해 주세요.
