---
name: prr-add-reviewer
description: PRR 리뷰어 추가 스킬. 사용자가 /prr-add-reviewer <owner/repo>를 실행할 때 동작한다. 프로젝트 env.json을 읽어 맞춤형 리뷰어 후보를 추천하고, 사용자가 선택하면 페르소나·집중 항목·무시 항목을 자동 구성해 reviewer JSON을 생성·저장한다. prr-add-reviewer 또는 PRR 리뷰어 추가 요청이 있을 때 반드시 이 스킬을 사용한다.
---

# PRR — 리뷰어 추가

## 트리거
사용자가 `/prr-add-reviewer <owner/repo>` 를 실행할 때 동작한다.
예: `/prr-add-reviewer myorg/backend`

## PRR 설정 경로
PRR_DIR 은 사용자가 PRR을 클론한 경로다. 아래 명령으로 확인할 수 있다:
```bash
which prr | xargs dirname   # prr이 PATH에 등록된 경우
```

## 실행 절차

### Step 1 — 인수 파싱

- REPO = 첫 번째 인수 (형식: `owner/repo`)
- REPO_SLUG = REPO에서 `/`를 `__`로 치환 (예: `owner__repo`)
- CONFIG_DIR = `$PRR_DIR/configs/repos/$REPO_SLUG`

CONFIG_DIR 이 없으면: "오류: 등록되지 않은 리포입니다. `prr init <owner/repo>` 를 먼저 실행하세요." 출력 후 종료.

### Step 2 — 컨텍스트 파악

`$CONFIG_DIR/env.json` 을 읽어 프로젝트 특성(언어, 프레임워크, 의존성, 컨벤션)을 파악한다.

`$CONFIG_DIR/reviewers/` 디렉터리를 읽어 이미 등록된 리뷰어 id 목록을 수집한다.

### Step 3 — 리뷰어 후보 추천

프로젝트 특성을 바탕으로 이 코드베이스에 실질적으로 유용한 리뷰어 후보 4–6개를 구성한다.
단순히 "시니어/주니어" 나열이 아니라, 프레임워크·의존성에서 발생하는 실제 리스크를 고려한다.

예를 들어:
- Unity + Netcode 프로젝트라면 → 네트워크 동기화 전문가, 성능(GC·풀링) 전문가
- Next.js + Prisma라면 → DB 쿼리·N+1 전문가, 서버 컴포넌트 경계 전문가
- Go 서버라면 → 동시성·고루틴 누수 전문가, API 설계 전문가

각 후보 형식:
```
1. {id}   — {이 리뷰어가 무엇을 중점적으로 보는지 한 줄}
```

이미 등록된 id는 `(이미 등록됨)` 표시와 함께 선택 불가 처리한다.
목록 마지막에 "직접 입력" 옵션을 추가한다.

출력 후 사용자에게 번호 또는 직접 id 입력을 요청한다.

### Step 4 — JSON 자동 구성

선택된 id와 프로젝트 컨텍스트를 바탕으로 reviewer JSON을 구성한다.

필드 작성 기준:

| 필드 | 기준 |
|------|------|
| `id` | 선택한 id |
| `enabled` | `true` |
| `comment_header` | 역할에 어울리는 이모지 + 영문 명칭 (예: `"⚡ Performance Reviewer"`) |
| `persona` | 이 리뷰어의 역할·경험·관점을 서술하는 1–2문장. 구체적일수록 리뷰 품질이 높아진다 |
| `focus` | 이 리뷰어가 놓치면 안 되는 항목 3–5개. 프로젝트 기술 스택에 맞게 구체적으로 작성 |
| `ignore` | 이 리뷰어의 관심 밖인 항목 2–4개. 다른 리뷰어가 담당하거나 범위 밖인 것 |
| `output_language` | `"ko"` |
| `severity_threshold` | junior → `"low"`, 전문가/시니어 → `"medium"` |
| `lgtm_comment` | `true` |

생성한 JSON을 코드 블록으로 출력하고 확인을 구한다:
```
이 내용으로 저장할까요? [Y/n]
수정이 필요하면 어떤 부분을 바꿀지 알려주세요.
```

사용자가 수정을 요청하면 해당 부분만 수정 후 다시 출력한다. 확인이 날 때까지 반복한다.

### Step 5 — 저장

사용자가 확인(Y 또는 엔터)하면:
- 같은 id 파일이 이미 존재하면 덮어쓰기 전에 경고한다
- `$CONFIG_DIR/reviewers/{id}.json` 에 저장한다 (들여쓰기 2칸)

"✓ 리뷰어 '{id}' 추가 완료" 출력

### Step 6 — 다음 단계 안내

```
PR 리뷰를 실행하려면:
  /prr-review {REPO} <pr-number>

리뷰어를 직접 수정하려면:
  {저장된 파일 경로}
```
