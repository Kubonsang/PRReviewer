---
name: prr-scan
description: PRR 프로젝트 스캔. 사용자가 /prr-scan을 실행할 때 동작한다. 현재 디렉터리의 프로젝트 파일을 분석해 언어·프레임워크·의존성을 파악하고, .prr/env.json을 자동 생성한다. prr-scan 또는 PRR 환경 초기화 관련 요청이 있을 때 반드시 이 스킬을 사용한다.
---

## 변수
- `REPO` = `gh repo view --json nameWithOwner --jq '.nameWithOwner'` — 비어있으면 오류 후 종료
- `CONFIG_DIR` = `$(pwd)/.prr`
- `PRR_DIR` = `$(which prr | xargs dirname)`

## 프로젝트 분석
현재 디렉터리에서 읽을 파일: `package.json`, `pyproject.toml`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `Gemfile`, `Dockerfile`, `.github/workflows/*.yml`, `.eslintrc*`, 파일 확장자 빈도
→ 언어·런타임·프레임워크·테스트·린터·의존성·컨벤션 파악

## env.json 생성 및 저장
```json
{
  "repo": "", "languages": [], "runtime": "", "framework": "",
  "test_framework": "", "linter": "", "key_dependencies": [],
  "conventions": [],
  "review": { "exclude_paths": [], "max_diff_lines": 500, "on_update": "skip" }
}
```
- `exclude_paths`: lock 파일·빌드 산출물·생성 코드 자동 추론
- `conventions`: 린터 규칙·코딩 패턴 기반 추론

`mkdir -p "$CONFIG_DIR/reviewers"` 후 `$CONFIG_DIR/env.json` 저장 (들여쓰기 2칸).

`reviewers/` 비어있으면: `cp "$PRR_DIR/templates/reviewer_default.json" "$CONFIG_DIR/reviewers/junior.json"`

완료 출력:
```
✓ <owner/repo> 등록 완료
  .prr/env.json 저장됨 — 검토 후 필요하면 직접 수정하세요.
  기본 리뷰어(junior) 생성됨 — /prr-add-reviewer 로 리뷰어를 추가하세요.
```
