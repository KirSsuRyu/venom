---
description: 현재 프로젝트를 분석하여 .claude/ 전체를 이 프로젝트에 맞게 완전히 진화시킵니다. 새 파일 생성과 기존 파일 수정을 모두 수행합니다. 이 폴더를 새 프로젝트에 도입한 직후 한 번 실행하세요.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
---

# /venom — 프로젝트 완전 흡수

당신은 지금 이 가이드라인 세트(`CLAUDE.md` + `.claude/`)가 막 복사된 새 프로젝트의
루트에 있습니다. 당신의 임무는 **이 프로젝트를 깊이 이해하고, 그 이해를
영속적인 프로젝트 특화 규칙·스킬·훅·메모리로 응결시키는 것**입니다.

> `/venom`은 **항상 최대 깊이**로 동작합니다.
> 새 파일 생성, 기존 파일 진화, 코드 샘플링, 신규 hook 작성을 모두 수행합니다.

---

## 0단계: 사전 점검

1. 현재 작업 디렉토리가 프로젝트 루트인가? (`CLAUDE.md`와 `.claude/`가 함께 있어야 함)
2. 이전에 흡수한 흔적이 있는가?
   - `.claude/rules/60-project.md`
   - `.claude/skills/project-*/`
   - `.claude/memory/decisions.md`의 `ADR-0002` 또는 그 후속 항목
3. 흔적이 있다면 사용자에게 *덮어쓸지, 보강할지, 중단할지* 묻고 답을 기다립니다.

> **참고**: 기존 `.claude/` 및 `CLAUDE.md`의 백업은 `npx @cgyou/venom-init`
> 설치 시 자동으로 수행됩니다. `/venom`에서는 별도 백업 없이 바로 진화합니다.

## 1단계: 프로젝트 메타데이터 수집 (병렬)

다음을 한꺼번에 조사합니다.

- **매니페스트/락파일**: `package.json`, `pyproject.toml`, `requirements*.txt`,
  `Cargo.toml`, `go.mod`, `Gemfile`, `pom.xml`, `build.gradle`, `composer.json`,
  `Pipfile`, `mix.exs`, `pubspec.yaml`, `Package.swift`
- **빌드 시스템**: `Makefile`, `Justfile`, `Taskfile.yml`, `Dockerfile`,
  `docker-compose.yml`, `.dockerignore`, `pnpm-workspace.yaml`, `nx.json`,
  `turbo.json`, `lerna.json`
- **CI 설정**: `.github/workflows/*`, `.gitlab-ci.yml`, `.circleci/config.yml`,
  `azure-pipelines.yml`, `Jenkinsfile`, `.buildkite/`
- **린트/포맷 설정**: `.eslintrc*`, `.prettierrc*`, `ruff.toml`, `pyproject.toml`의
  `[tool.*]`, `.editorconfig`, `.rubocop.yml`, `rustfmt.toml`, `.golangci.yml`,
  `biome.json`
- **테스트 프레임워크**: `pytest.ini`, `jest.config.*`, `vitest.config.*`,
  `phpunit.xml`, `playwright.config.*`, `cypress.config.*`
- **문서**: `README*`, `CONTRIBUTING*`, `ARCHITECTURE*`, `docs/`, `ADR/`
- **환경**: `.env.example`, `.envrc`, `.tool-versions`, `.nvmrc`,
  `.python-version`, `mise.toml`, `asdf` 설정
- **VCS**: `git log --oneline -20`, `git remote -v`, `git branch -a`,
  최근 6개월 커밋의 prefix 패턴, 활성 PR 템플릿

각 발견 사항을 한 줄 메모로 정리합니다.

## 2단계: 디렉토리 구조 매핑 및 코드 심층 샘플링

- `find . -maxdepth 3 -type d` (Glob 또는 Bash)로 상위 구조 파악.
- 소스 루트 식별 (`src/`, `lib/`, `app/`, `pkg/`, `internal/` 등).
- 테스트 루트 식별 (`tests/`, `__tests__/`, `spec/`, `test/`).
- 모노레포 여부 (`packages/`, `apps/`, workspace 매니페스트).
- 자동 생성 디렉토리 (`generated/`, `*_pb2.py`, `__generated__/`).
- 무시 디렉토리 (`.gitignore` 파싱 + `protect-paths.sh` 목록과 교차).

**코드 심층 샘플링** (최소 10~15개 파일):
핵심 디렉토리(소스 루트, 테스트 루트, 진입점)에서 **가장 큰 파일**,
**가장 최근 수정된 파일**, **import가 가장 많은 파일**(허브 모듈)을
각 2~3개씩 직접 읽습니다. 관찰 항목:
- 스타일/네이밍/에러 처리/로깅 컨벤션
- 반복되는 디자인 패턴 (Repository, Service, Controller, Factory, Observer 등)
- 의존성 주입 방식 (DI 컨테이너, 수동 주입, 데코레이터 등)
- 에러 타입 계층 (커스텀 예외 클래스, 에러 코드 체계)
- 데이터 흐름 (요청 → 검증 → 비즈니스 로직 → 저장 → 응답)

## 3단계: 도메인 심층 분석

### 3A. 컨벤션 추출

읽은 자료에서 다음을 도출합니다. 확신할 수 없는 항목은 *추측하지 않고*
사용자 질문 후보 목록에 모아둡니다.

- **언어와 버전**, **패키지 매니저**, **주요 프레임워크**
- **빌드/테스트/린트/타입체크/포맷/dev 서버 명령**
- **네이밍 컨벤션** (camelCase vs snake_case, 파일/디렉토리 규칙)
- **모듈 경계** (레이어, 도메인 분리, public API 표면)
- **테스트 전략** (단위/통합/E2E의 위치와 명령, 픽스처 패턴)
- **금기 사항** (직접 편집 금지 디렉토리, 자동 생성 코드, 마이그레이션 파일)
- **CI 게이트** (PR 머지 전 반드시 통과해야 하는 체크)
- **브랜치/릴리스 흐름** (trunk-based, gitflow, release-please 등)
- **로깅·관측 스택**, **에러 처리 패턴**, **DI/IoC 컨테이너**
- **민감 데이터 패턴** (이 프로젝트에서 절대 로깅/커밋되면 안 되는 것)

### 3B. 아키텍처 패턴 분석

코드 샘플링에서 관찰한 내용을 토대로 다음을 식별합니다:

- **아키텍처 스타일**: 레이어드(MVC/Clean/Hexagonal), 이벤트 드리븐,
  마이크로서비스, 모놀리스, CQRS, 서버리스, 파이프라인 등
- **레이어 의존 규칙**: 어느 레이어가 어느 레이어를 import하는가?
  역방향 의존이 있으면 위반으로 기록
- **모듈 간 통신**: 직접 호출, 이벤트 버스, 메시지 큐, REST/gRPC, 공유 DB
- **상태 관리**: 글로벌 상태, 세션, 캐시 레이어, 상태 머신
- **데이터 계층**: ORM/ODM, 리포지토리 패턴, 직접 SQL, 마이그레이션 도구
- **인증/인가 패턴**: 미들웨어, 데코레이터, 가드, RBAC/ABAC
- **API 계약**: REST 버저닝, GraphQL 스키마, Proto 정의, OpenAPI spec

### 3C. 도메인 모델 분석

프로젝트의 핵심 비즈니스 도메인을 파악합니다:

- **핵심 엔티티**: 주요 모델/타입/인터페이스와 그 관계
- **바운디드 컨텍스트**: 도메인이 어떻게 나뉘어 있는가
- **불변 규칙(invariants)**: 코드에서 발견되는 비즈니스 규칙 검증
  (예: "주문 금액은 0 이상이어야 한다", "사용자는 중복 이메일 불가")
- **도메인 이벤트**: 시스템에서 발생하는 주요 이벤트 흐름
- **외부 의존**: 외부 API, 결제 게이트웨이, 메일 서비스, 저장소 등
- **도메인 용어 사전**: 코드에서 반복 사용되는 비즈니스 용어와 그 의미

### 3D. 개발 패턴 카탈로그

코드에서 *실제로 사용되는* 패턴을 카탈로그화합니다:

- **생성 패턴**: Factory, Builder, Singleton, DI
- **구조 패턴**: Adapter, Decorator, Facade, Proxy, Repository
- **행동 패턴**: Strategy, Observer, Command, Pipeline/Middleware, State
- **에러 처리 패턴**: Result/Either 타입, 커스텀 예외 계층, 에러 코드 체계,
  글로벌 에러 핸들러, retry 정책
- **비동기 패턴**: async/await, 큐 기반, 이벤트 루프, 워커, 스트림
- **테스트 패턴**: 테스트 헬퍼, 팩토리, 픽스처, 모킹 전략, 테스트 데이터 관리
- **인프라 패턴**: 환경별 설정, 헬스체크, 그레이스풀 셧다운, 마이그레이션

각 패턴은 *실제 코드 위치*와 함께 기록합니다. 추측이 아닌 관찰에 기반합니다.

---

## 4단계: 새 파일 생성

다음을 새로 만듭니다(또는 기존이 있으면 보강). 3단계에서 분석한 도메인, 아키텍처,
개발 패턴을 모두 반영하여 **이 프로젝트에 최적화된** 파일을 만듭니다.

### 4.1 `.claude/rules/60-project.md`
프로젝트 특화 규칙. 다음을 *반드시* 포함:
- **스택 요약**: 언어, 프레임워크, 주요 라이브러리, 빌드 도구
- **디렉토리 지도**: 소스/테스트/설정/인프라 위치와 각각의 역할
- **빌드/테스트/린트/포맷 명령**: 정확한 명령과 플래그
- **CI 게이트**: PR 머지 전 통과해야 하는 체크 목록
- **함정 목록**: 코드 샘플링에서 발견한 비자명한 제약

### 4.2 `.claude/rules/61-architecture.md` *(신규)*
3B 아키텍처 분석 결과를 규칙으로 응결:
- **레이어 의존 방향**: 허용/금지 import 방향 명시 (예: "controller → service OK, service → controller 금지")
- **모듈 경계 규칙**: 어떤 모듈이 어떤 모듈에 접근 가능한지
- **공개 API 규칙**: 외부 노출 인터페이스 변경 시 주의사항
- **신규 모듈 추가 규칙**: 새 모듈/패키지 생성 시 따라야 하는 패턴
- **데이터 흐름 규칙**: 요청→응답 경로에서 반드시 거쳐야 하는 계층

### 4.3 `.claude/rules/62-domain.md` *(신규)*
3C 도메인 분석 결과를 규칙으로 응결:
- **도메인 용어 사전**: 코드에서 사용되는 핵심 비즈니스 용어와 정의
- **불변 규칙**: 코드에서 발견된 비즈니스 규칙 (위반 시 버그)
- **엔티티 관계**: 핵심 모델 간 관계와 생성/수정/삭제 규칙
- **금기 패턴**: 이 도메인에서 절대 하면 안 되는 것
  (예: "Order를 직접 삭제하지 않는다, soft delete만 허용")
- **외부 의존 규칙**: 외부 API/서비스 호출 시 retry, timeout, fallback 정책

### 4.4 `.claude/rules/63-patterns.md` *(신규)*
3D 개발 패턴 카탈로그를 규칙으로 응결:
- **이 프로젝트에서 사용하는 패턴 목록**: 각 패턴의 위치와 사용법
- **새 코드 작성 시 따라야 하는 패턴**: 어떤 상황에 어떤 패턴을 쓰는가
- **에러 처리 규칙**: 이 프로젝트의 에러 타입 계층, 에러 코드 체계, 재시도 정책
- **비동기 규칙**: async 코드 작성 시 따라야 하는 패턴
- **테스트 작성 패턴**: 이 프로젝트의 테스트 헬퍼, 팩토리, 모킹 전략

### 4.5 `.claude/skills/project-build/SKILL.md`
이 프로젝트의 빌드/테스트/린트/포맷을 *정확한* 명령·플래그·작업 디렉토리로
실행하는 스킬. 모노레포라면 workspace 필터까지 포함.

### 4.6 `.claude/skills/project-architecture/SKILL.md`
모듈 트리, 레이어 의존 방향, public API 경계, 핵심 추상화.
코드 샘플링 결과를 기반으로 실제 패턴과 예제를 포함.
3B/3C/3D 분석의 시각적 요약 역할.

### 4.7 `.claude/skills/project-domain/SKILL.md` *(신규)*
도메인 지식 가이드:
- 새 기능 추가 시 영향받는 엔티티와 바운디드 컨텍스트 식별 방법
- 비즈니스 로직 변경 시 불변 규칙 검증 체크리스트
- 도메인 이벤트 추가/수정 시 따라야 하는 절차

### 4.8 `.claude/memory/decisions.md`에 ADR 추가
```markdown
## ADR-NNNN: /venom 실행 — <YYYY-MM-DD>
- 상태: 채택
- 맥락: 이 프로젝트의 컨벤션을 가이드라인 세트에 흡수시키기 위해 실행.
- 결정: 다음 파일을 생성/수정함 — <목록>
- 결과: 다음 세션부터 Claude가 이 프로젝트의 컨벤션을 자동으로 따른다.
```

### 4.9 `.claude/memory/lessons.md`에 즉석 교훈 추가
흡수 과정에서 발견한 비자명한 사실(예: "테스트는 반드시 `pnpm -w test`로
워크스페이스 루트에서 실행해야 한다", "User 모델은 항상 UserService.save()를
거쳐야 audit 로그가 남는다")을 즉시 기록합니다.

### 4.10 이 프로젝트의 권장 스킬 체인 도출

1~3단계 분석 결과를 바탕으로 **이 프로젝트에서 실제로 쓸 스킬 흐름**을 도출합니다.
7단계 보고에 포함할 재료가 됩니다.

판단 기준:

| 감지된 특성 | 체인에 추가할 스킬 |
|---|---|
| 인증·결제·개인정보 처리 코드 | `code-review` → **보안 감사 모드** 명시 |
| 복잡한 비즈니스 로직 / 과거 버그 기록 | `debug-loop` 전면 배치 |
| 테스트 프레임워크 존재 | `test-runner` 체인에 포함 |
| PR 기반 협업 (브랜치 전략 확인) | `git-workflow` + PR 템플릿 |
| feat: 커밋이 많은 활발한 개발 | 주간 `retro` 권장 |
| DB·마이그레이션 존재 | `project-build`(마이그레이션 포함) 강조 |

도출한 체인을 **단계 이름 → 스킬 이름** 형태로 정리해둡니다.

---

## 5단계: 기존 파일 진화

기존 범용 파일을 이 프로젝트에 맞게 *진화*시킵니다.
변경 전후 이유는 모두 ADR에 기록.

### 5.1 `CLAUDE.md` 진화
- 부록 목록에 새로 추가된 `60-project.md`와 그 외 신규 규칙 파일을 등재.
- 프로젝트 고유 어휘(예: 도메인 용어)가 있다면 짧은 용어집 섹션을 추가.
- 150줄 예산을 넘지 않도록 다른 곳에서 줄여야 한다면 줄인다.

### 5.2 `.claude/rules/` 진화
- `10-coding-standards.md`: 이 프로젝트의 실제 네이밍 규칙·줄 길이·import
  순서·에러 처리 패턴으로 *교체*. 코드 샘플링에서 관측한 결과에 따라 단정.
- `20-security.md`: 이 프로젝트의 민감 데이터 패턴(예: customer_id는 로깅 금지),
  사용 중인 비밀 관리 방식(Vault, AWS Secrets Manager, doppler 등)을 추가.
- `30-git-commit.md`: 실제 사용 중인 커밋 prefix 규약(conventional commits,
  jira 키 prefix 등)과 브랜치 명명, 머지 정책을 반영.
- `40-testing.md`: 실제 테스트 위치·명명 규칙·픽스처 패턴·CI 게이트로 교체.
- 필요하면 `45-logging.md`, `46-observability.md`, `47-i18n.md` 같은
  새 도메인 규칙 파일을 추가.

### 5.3 `.claude/skills/` 진화

#### 기존 스킬 진화
- `test-runner/SKILL.md`: 이 프로젝트의 정확한 명령·인자·환경 변수로 교체.
- `code-review/SKILL.md`: 이 프로젝트의 CI 게이트, 아키텍처 규칙 위반 체크,
  도메인 불변 규칙 검증, 알려진 함정을 체크리스트에 추가.
- `git-workflow/SKILL.md`: 실제 PR 템플릿, 라벨, 리뷰어 규칙을 반영.
- `debug-loop/SKILL.md`: 이 프로젝트의 로깅 시스템, 디버깅 도구, 관측 스택에
  맞춰 진단 단계를 구체화. (예: "먼저 Datadog/Sentry에서 트레이스를 확인")

#### 신규 스킬 — 프로젝트 분석 결과에 따라 해당하는 것을 모두 생성

**인프라/운영 스킬:**
- `db-migration/SKILL.md` — DB가 있는 경우: 마이그레이션 도구·명령·롤백 절차·
  스키마 변경 시 체크리스트 (인덱스, 다운타임, 데이터 마이그레이션)
- `release/SKILL.md` — 릴리스 절차·체인지로그 갱신·태깅·배포 파이프라인
- `deployment/SKILL.md` — 배포 환경(Docker, K8s, serverless 등)별 절차·
  롤백 방법·환경별 설정 관리
- `infra-config/SKILL.md` — 인프라 설정(terraform, helm, CDK 등) 변경 절차

**도메인/비즈니스 스킬:**
- `domain-modeling/SKILL.md` — 새 엔티티/값 객체 추가 시 따라야 하는 절차,
  바운디드 컨텍스트 간 통신 규칙, 도메인 이벤트 발행 패턴
- `api-contract/SKILL.md` — OpenAPI/Proto/GraphQL 스키마 변경 절차,
  버전 관리, 하위 호환성 체크, 클라이언트 영향 분석
- `feature-flag/SKILL.md` — 플래그 도입·점진적 롤아웃·제거 절차

**품질/보안 스킬:**
- `performance/SKILL.md` — 성능 프로파일링 도구·명령, 벤치마크 작성법,
  N+1 쿼리 탐지, 메모리 누수 진단 절차
- `security-audit/SKILL.md` — 이 프로젝트의 인증/인가 흐름 검증,
  OWASP 체크리스트의 프로젝트 특화 버전, 의존성 취약점 스캔 명령
- `refactoring/SKILL.md` — 이 프로젝트의 아키텍처 패턴에 맞는 안전한
  리팩토링 절차 (레이어 이동, 모듈 분리, 인터페이스 추출 등)

**개발 생산성 스킬:**
- `new-feature/SKILL.md` — 새 기능 추가 시 end-to-end 가이드:
  엔티티 생성 → 서비스 로직 → API 엔드포인트 → 테스트 → 문서 갱신
- `new-module/SKILL.md` — 새 모듈/패키지 생성 시 보일러플레이트와
  디렉토리 구조, 필수 파일 목록, 등록 절차
- `dependency-update/SKILL.md` — 의존성 업데이트 절차, 호환성 확인,
  breaking change 대응, 락파일 갱신

**프로젝트에 해당 도메인이 없으면 해당 스킬을 만들지 않습니다.**
어떤 스킬을 만들지는 1~3단계의 분석 결과에 기반하여 판단합니다.

### 5.4 `.claude/hooks/` 진화

#### 기존 hook 진화
- `auto-format.sh`: 이 프로젝트가 실제로 사용하는 포매터와 정확한 인자로 단순화.
- `block-dangerous.sh` + `lib/dangerous-patterns.sh`: 이 프로젝트 고유의
  위험 명령 패턴 추가 (예: `prisma migrate reset`, `terraform destroy`,
  `helm uninstall`, `kubectl delete -n production`, 운영 DB 직접 접근,
  프로덕션 환경 대상 명령).
- `protect-paths.sh`: 이 프로젝트의 자동 생성 디렉토리, 마이그레이션 파일,
  스냅샷, 골든 파일, API 스키마 생성물 등을 보호 목록에 추가.
- `inject-context.sh`: 이 프로젝트에서 유용한 추가 컨텍스트(현재 활성 feature
  flag, 최근 마이그레이션 상태 등)를 주입.

#### 신규 hook — 프로젝트 분석 결과에 따라 해당하는 것을 모두 생성

**아키텍처 보호 hook:**
- `enforce-layer-deps.sh` (PreToolUse: Write|Edit) — 레이어 의존 방향 위반 감지.
  예: controller에서 repository 직접 import 차단, 도메인 레이어에서 인프라 import 차단.
  3B 아키텍처 분석에서 도출한 레이어 규칙을 패턴 매칭으로 강제.
- `enforce-module-boundary.sh` (PreToolUse: Write|Edit) — 모듈 경계 위반 감지.
  internal/ 패키지의 외부 import 차단, 바운디드 컨텍스트 간 직접 참조 차단.

**도메인 보호 hook:**
- `block-prod-config.sh` (PreToolUse: Write|Edit) — `production.yml`,
  `prod.env`, 프로덕션 설정 파일류 편집 차단.
- `protect-migration.sh` (PreToolUse: Write|Edit) — 이미 적용된 마이그레이션
  파일 수정 차단. 새 마이그레이션만 추가 가능.
- `protect-api-contract.sh` (PreToolUse: Write|Edit) — API 스키마(OpenAPI,
  Proto, GraphQL)의 breaking change 감지 및 경고.

**품질 강제 hook:**
- `enforce-test-with-code.sh` (PostToolUse: Write|Edit) — 소스 파일 편집 시
  같은 모듈에 테스트가 있는지 확인. 없으면 경고 메시지 출력.
- `pre-commit-style-check.sh` (PreToolUse: Edit) — 이 프로젝트의 네이밍/스타일
  컨벤션 위반을 사전 차단 (예: snake_case 프로젝트에서 camelCase 사용).
- `enforce-error-pattern.sh` (PostToolUse: Write|Edit) — 이 프로젝트의 에러
  처리 패턴(커스텀 예외 사용, Result 타입 등) 준수 여부 검사.

**컨텍스트 주입 hook:**
- `inject-schema.sh` (UserPromptSubmit) — DB 스키마/타입 정의/API 계약을
  컨텍스트에 주입하여 Claude가 항상 최신 데이터 구조를 인식.
- `inject-domain-glossary.sh` (UserPromptSubmit) — 도메인 용어 사전을
  컨텍스트에 주입하여 비즈니스 용어의 일관된 사용을 보장.

**프로젝트에 해당 도메인이 없으면 해당 hook을 만들지 않습니다.**
어떤 hook을 만들지는 1~3단계의 분석 결과에 기반하여 판단합니다.

새 hook을 추가하면 반드시:
1. `settings.json`의 적절한 이벤트 배열에 등록
2. JSON 유효성을 `python3 -c "import json; json.load(open('.claude/settings.json'))"`로 검증
3. `bash -n`으로 문법 검증
4. `chmod +x`로 실행 권한 부여
5. 대표적인 입력으로 스모크 테스트

### 5.5 `.claude/settings.json` 진화
- `permissions.allow`: 이 프로젝트의 안전한 빌드/테스트/린트 명령을 추가하여
  사용자 승인 클릭을 줄임.
- `permissions.deny`: 이 프로젝트의 위험 명령을 명시적으로 차단.
- `env`: 프로젝트 표준 환경 변수 추가 (단, 비밀 값은 *절대* 넣지 않음).

### 5.6 `.claude/memory/` 보강
- 흡수 과정에서 새로 알게 된 함정·관례를 모두 `lessons.md`에 기록.
- 흡수 자체를 ADR로 남김.

---

## 6단계: 검증

- 생성/수정한 각 파일을 다시 읽어 사실 오류를 확인합니다.
- 추출한 빌드/테스트/린트 명령을 *실제로* 한 번씩 실행해봅니다
  (각각 5분 이내 타임아웃, 실패해도 OK — 명령 자체의 존재만 확인).
- 명령이 존재하지 않으면 해당 줄을 제거하거나 "(미확인)"으로 표시합니다.
- 신규/수정 hook 스크립트는 `bash -n`으로 문법 검증하고
  `chmod +x`로 실행 권한을 부여합니다.
- `.claude/settings.json`을 JSON 유효성 검사합니다.
- 대표적인 위험 명령을 hook에 stdin으로 흘려 차단되는지 스모크 테스트합니다.

## 7단계: 사용자 보고

다음 형식으로 끝맺습니다.

```
## /venom 결과 — <YYYY-MM-DD>

### 감지된 스택
- 언어: ...
- 패키지 매니저: ...
- 프레임워크: ...
- CI: ...
- 모노레포: ...

### 새로 생성된 파일
- ...

### 진화된 기존 파일
- ...

### 새로 추가된 hook
- ...

### 검증 결과
- ✅ 빌드 명령: ...
- ✅ 테스트 명령: ...
- ⚠️ 린트: 미발견
- ✅ JSON 유효성: OK
- ✅ hook 문법: OK
- ✅ hook 스모크 테스트: <개수>/<개수> 통과

### 🔗 권장 스킬 체인
이 프로젝트에서 작업할 때 권장하는 스킬 실행 순서입니다.
(4.10단계에서 도출한 결과를 여기에 채웁니다)

**일반 기능 개발 흐름:**
```
구현 → code-review → test-runner → git-workflow
```

**버그 수정 흐름:**
```
debug-loop → test-runner → code-review → git-workflow
```

**보안 민감 변경 흐름:**  ← 인증·결제·개인정보 코드가 있는 경우에만
```
구현 → code-review (보안 감사 모드) → test-runner → git-workflow
```

**주간 마무리:**
```
retro  ← 매주 금요일 또는 스프린트 종료 시
```

> 위 흐름은 분석 결과 기반의 권장안입니다. 프로젝트 특성에 맞게 조정하세요.

### 사용자에게 묻고 싶은 것
1. ...
2. ...

### 되돌리는 방법
`npx @cgyou/venom-init` 설치 시 생성된 백업에서 복원하거나,
`git checkout -- .claude/ CLAUDE.md`로 되돌릴 수 있습니다.

이 프로젝트는 흡수되었습니다. 다음 세션부터 Claude는 위 컨벤션을 자동으로 따릅니다.

Venom은 이제 살아있습니다.
- 실수에서 규칙이 태어납니다 (같은 실수 2회 → 규칙/hook 자동 강화)
- 반복에서 스킬이 태어납니다 (같은 패턴 3회 → 스킬 자동 추출)
- 매 세션 시작 시 메모리를 읽고, 종료 시 진화 기회를 감지합니다
- 자세한 진화 프로토콜: .claude/rules/55-self-evolution.md
```

---

## 8단계: 자기 진화 씨앗 심기

`/venom`은 최초 흡수이지만, Venom이 계속 살아있으려면 자기 진화 메커니즘이
심어져 있어야 합니다. 다음을 확인합니다:

1. **55-self-evolution.md**가 `.claude/rules/`에 존재하는가?
   - 없으면 기본 버전을 생성한다.
2. **evolve 스킬**이 `.claude/skills/evolve/SKILL.md`에 존재하는가?
   - 없으면 기본 버전을 생성한다.
3. **trigger-evolution.sh**가 `.claude/hooks/`에 존재하고
   `settings.json`의 Stop 이벤트에 등록되어 있는가?
   - 없으면 기본 버전을 생성하고 등록한다.
4. **session-start.sh**가 진화 상태(반복 실수 태그)를 주입하는가?
   - 안 하면 해당 로직을 추가한다.

이 4가지가 갖춰지면 Venom은 `/venom` 실행 이후에도 **매 세션, 매 작업에서
스스로 배우고 진화하는 살아있는 심비오트**가 됩니다.

---

## 절대 규칙

- **추측하지 않는다.** 확신할 수 없는 항목은 사용자 질문 목록에 둔다.
  잘못 단정한 규칙은 잘못된 판단을 영속화한다.
- **비밀을 흡수하지 않는다.** `.env`, `id_rsa`, 자격증명 파일을 읽지 않는다.
  `protect-paths` hook이 어차피 차단하지만, 시도조차 하지 않는다.
- **메모리에 PII/비밀을 쓰지 않는다.** 비밀이 들어갈 수 있는 패턴은
  변수명·경로·구조만 기록하고 값은 절대 기록하지 않는다.
- **흡수가 끝나도 커밋하지 않는다.** 사용자가 결과를 검토한 뒤 직접 커밋한다.
- **`memory/`를 정리(prune)하지 않는다.** 흡수와 무관한 과거 기록은 그대로 둔다.
