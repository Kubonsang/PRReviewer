---
name: prr-review
description: PRR PR 코드 리뷰어. 사용자가 /prr-review <pr-number>를 실행할 때 동작한다. 현재 디렉터리의 .prr/ 설정을 읽어 리뷰어 페르소나별로 GitHub PR diff를 분석하고, 각 리뷰어 이름으로 GitHub 코멘트를 자동 게시한다. prr-review 또는 PR 리뷰 자동화 관련 요청이 있을 때 반드시 이 스킬을 사용한다.
---

## 변수
- `PR_NUMBER` = 첫 번째 인수
- `CONFIG_DIR` = `$(pwd)/.prr`
- `PRR_DIR` = `$(which prr | xargs dirname)`
- `REPO` = `gh repo view --json nameWithOwner --jq '.nameWithOwner'` — 비어있으면 오류 후 종료

## 설정 로드
`$CONFIG_DIR/env.json` 없으면 오류 후 종료. `review.exclude_paths`, `review.on_update` 추출.
`$CONFIG_DIR/reviewers/` 에서 `"enabled": true` 파일 수집. 없으면 오류 후 종료.

## Diff 수집
`gh pr diff <PR_NUMBER> --repo <REPO>` → `diff --git` 단위로 분리 → `exclude_paths`(fnmatch) 필터링 → 비면 종료.

`on_update="review"` 이면: `bash $PRR_DIR/scripts/delete_prr_comments.sh <REPO> <PR_NUMBER>`

## 리뷰어별 리뷰

각 리뷰어 JSON 필드: `comment_header`, `persona`, `focus`, `rules`(선택), `ignore`, `severity_threshold`(low/medium/high), `lgtm_comment`, `tone`, `comment_sections`(기본 `["issues"]`)

**지침:** persona 관점 채택. focus 중심 검토, ignore 제외. severity_threshold 미만 생략. diff에 없는 라인 이슈 보고 금지. 근거 약하면 추측임을 밝힘. tone 말투 유지.

**rules 체크:** 각 규칙(문자열 또는 `{rule, reason?, example?}`)을 diff에 대입해 위반 여부 판단. 위반 시 인라인 코멘트에 규칙명 명시. 위반 없으면 생략.

**이슈 기록:** `path`(파일경로), `line`(새 파일 기준 줄번호, `@@` 헝크에서 계산), `side`(`"RIGHT"` 추가/수정, `"LEFT"` 삭제)

## 코멘트 게시

**인라인 (이슈 1개당):**
```
> **심각도:** low|medium|high
> **규칙 위반:** {규칙명}  ← rules 위반 시에만

{문제 설명과 개선 제안. tone 말투.}

<!-- PRR-INLINE -->
```

**요약 PR 코멘트** (`comment_sections`에서 `issues` 제외한 섹션):
- `review_basis`: focus·ignore 요약
- `praise`: 잘된 코드 언급 (없으면 섹션 생략)
- `summary`: tone 마무리

```
## {comment_header}

{인사 한 문장}
### 📋 리뷰 기준 / ### ✨ 잘한 점 / ### 💬 마무리

---
🤖 *이 리뷰는 AI가 작성했습니다.*
<!-- PRR-AUTO-REVIEW -->
```

이슈 없고 `lgtm_comment: true`면 `### ✅ LGTM` 섹션 추가.

**게시:**
```bash
TMPFILE=$(mktemp /tmp/prr_review_XXXXXX.json)
trap 'rm -f "$TMPFILE"' EXIT
# { "body": "...", "comments": [{"path":"...","line":N,"side":"RIGHT","body":"..."},...] }
bash "$PRR_DIR/scripts/post_review.sh" "<REPO>" "<PR_NUMBER>" "$TMPFILE"
```

완료: `✓ PR #<PR_NUMBER> 리뷰 완료 (<N>개 리뷰어)` 출력
