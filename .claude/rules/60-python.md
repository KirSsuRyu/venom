# 60 — Python 부록 규칙 (샘플)

> 이것은 *예시* 규칙 파일입니다. `/venom deep`이 본받을 패턴을 보여줍니다.
> Python 프로젝트가 아니라면 이 파일을 삭제하거나 해당 스택용으로 교체하세요.
> 60-/70- 접두어 파일은 자동 로드되어 `10-coding-standards.md`를 *덮어씁니다*.

## 도구 (이 프로젝트의 정확한 명령으로 교체)

- **포매터**: `ruff format` (또는 `black`)
- **린터**: `ruff check --fix`
- **타입체커**: `mypy --strict src/`
- **테스트**: `pytest -q`
- **의존성**: `uv sync` (또는 `poetry install`, `pip-sync`)

## 스타일

- 줄 길이 100자(`ruff` 기본). 주변 파일이 다르면 따른다.
- import 순서: stdlib → 서드파티 → 로컬. `ruff`/`isort`가 강제.
- f-string 우선. `%` 포매팅과 `.format()` 금지(레거시 외).
- public 함수/클래스에는 한 줄 docstring(*무엇*과 *왜*).
- 타입 힌트는 public API에 필수, 내부 헬퍼는 선택.

## 예외 처리

- 베어 `except:` 금지. 항상 구체 예외를 잡는다.
- `except Exception:`도 boundary(웹 핸들러, 큐 컨슈머)에서만 허용하고
  반드시 컨텍스트 로깅 후 재던지거나 도메인 예외로 래핑한다.
- `pass`로 예외를 삼키지 않는다.

## 비동기

- `async def` 안에서 동기 블로킹 호출 금지. CPU 바운드는 `run_in_executor`,
  I/O는 비동기 클라이언트 사용.
- `asyncio.gather`로 동시 실행 시 예외 전파를 명시적으로 처리한다.

## 함정

- mutable default arg(`def f(x=[])`) 금지. `None` 후 `or []`.
- `dict.keys()` 순회 중 mutation 금지. `list(dict.keys())`로 스냅샷.
- pandas/numpy 인덱싱은 `.loc`/`.iloc` 명시. chained assignment 금지.
- `datetime.utcnow()` 금지. 타임존 인식 `datetime.now(UTC)` 사용.

## 테스트

- 위치: `tests/` 미러 구조 (`src/foo/bar.py` ↔ `tests/foo/test_bar.py`).
- 픽스처: `conftest.py` 가까운 곳에. 글로벌 자제.
- 외부 I/O는 `pytest-mock` 또는 `respx`/`httpx_mock`로 격리.
- 통합 테스트는 `@pytest.mark.integration` 마커, 기본 실행에서 제외.
