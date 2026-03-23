---
name: prr-scan
description: PRR 프로젝트 스캔. 사용자가 /prr-scan을 실행할 때 동작한다. 현재 디렉터리의 프로젝트 파일을 분석해 언어·프레임워크·의존성을 파악하고, .prr/env.json을 자동 생성한다. prr-scan 또는 PRR 환경 초기화 관련 요청이 있을 때 반드시 이 스킬을 사용한다.
---

# PRR — 프로젝트 스캔

## 트리거
사용자가 `/prr-scan` 을 실행할 때 동작한다.
**현재 디렉터리**가 리뷰 대상 프로젝트 루트여야 한다.

## PRR 설정 경로
PRR_DIR 은 사용자가 PRR을 클론한 경로다. 아래 명령으로 확인할 수 있다:
```bash
which prr | xargs dirname
```

## 실행 절차

### Step 1 — 리포 감지

현재 디렉터리에서 GitHub 리포를 감지한다:
```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)
```

REPO가 비어있으면: "오류: GitHub 리포를 감지할 수 없습니다. `gh repo view`가 동작하는 디렉터리에서 실행하세요." 출력 후 종료.

- CONFIG_DIR = `$(pwd)/.prr`

### Step 2 — 프로젝트 분석

현재 디렉터리에서 아래 파일들을 읽어 프로젝트 특성을 파악한다.

| 파일 | 파악 정보 |
|------|----------|
| `package.json` | JS/TS 런타임, 프레임워크, 의존성 |
| `pyproject.toml`, `requirements.txt` | Python 버전, 의존성 |
| `go.mod` | Go 버전, 모듈명 |
| `Cargo.toml` | Rust 에디션, 의존성 |
| `pom.xml`, `build.gradle` | Java/Kotlin, 의존성 |
| `Gemfile` | Ruby 버전, 의존성 |
| `Dockerfile` | 런타임 환경 |
| `.github/workflows/*.yml` | CI 환경 |
| `.eslintrc*`, `pyproject.toml` | 린터/포매터 |
| 파일 확장자 빈도 | 주 사용 언어 판별 |

### Step 3 — env.json 생성

분석 결과를 아래 스키마로 구성한다.
- `exclude_paths` 는 프로젝트 유형에 맞게 자동 추론한다 (lock 파일, 빌드 산출물, 생성 코드 등)
- `conventions` 는 발견된 코딩 패턴과 린터 규칙을 기반으로 추론한다

```json
{
  "repo": "<owner/repo>",
  "languages": [],
  "runtime": "",
  "framework": "",
  "test_framework": "",
  "linter": "",
  "key_dependencies": [],
  "conventions": [],
  "review": {
    "exclude_paths": [],
    "max_diff_lines": 500,
    "on_update": "skip"
  }
}
```

### Step 4 — 저장 및 초기화

```bash
mkdir -p "$CONFIG_DIR/reviewers"
```

`$CONFIG_DIR/env.json` 에 저장한다 (들여쓰기 2칸).

`$CONFIG_DIR/reviewers/` 가 비어있으면 기본 리뷰어 템플릿을 복사한다:
```bash
cp "$PRR_DIR/templates/reviewer_default.json" "$CONFIG_DIR/reviewers/junior.json"
```

저장 후 파일 내용을 출력하고:
```
✓ <owner/repo> 등록 완료
  .prr/env.json 저장됨 — 검토 후 필요하면 직접 수정하세요.
  기본 리뷰어(junior) 생성됨 — /prr-add-reviewer 로 리뷰어를 추가하세요.
```
