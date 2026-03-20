# PRR — PR 코드 리뷰어

## 트리거
사용자가 `/prr-review <owner/repo> <pr-number>` 를 실행할 때 동작한다.
예: `/prr-review myorg/backend 42`

## PRR 설정 경로
PRR_DIR 은 사용자가 PRR을 클론한 경로다. 아래 명령으로 확인할 수 있다:
```bash
which prr | xargs dirname   # prr이 PATH에 등록된 경우
```
또는 `~/.zshrc` 에서 `export PATH` 에 추가한 경로를 사용한다.

## 실행 절차

### Step 1 — 인수 파싱
- REPO = 첫 번째 인수 (형식: `owner/repo`)
- PR_NUMBER = 두 번째 인수 (숫자)
- REPO_SLUG = REPO에서 `/`를 `__`로 치환 (예: `owner__repo`)
- CONFIG_DIR = `$PRR_DIR/configs/repos/$REPO_SLUG`

### Step 2 — 설정 파일 로드

`$CONFIG_DIR/env.json` 을 읽는다.
파일이 없으면: "오류: 등록된 리포가 아닙니다. `prr init <owner/repo>` 를 먼저 실행하세요." 출력 후 종료.

env.json에서 추출:
- `review.exclude_paths` → 제외할 파일 패턴 목록
- `review.on_update` → `"skip"` | `"review"`

`$CONFIG_DIR/reviewers/` 에서 `"enabled": true` 인 JSON 파일 목록을 수집한다.
리뷰어가 없으면: "등록된 리뷰어가 없습니다. `prr reviewer add <owner/repo>` 를 실행하세요." 출력 후 종료.

### Step 3 — Diff 수집 및 필터링

```bash
gh pr diff <PR_NUMBER> --repo <REPO>
```

가져온 diff를 `diff --git a/<파일>` 단위 블록으로 분리한다.
`exclude_paths` 패턴(fnmatch 스타일)에 매칭되는 파일 블록을 제거한다.
필터링 후 diff가 비어있으면: "변경사항 없음 (exclude_paths 필터 적용 후)." 출력 후 종료.

### Step 4 — 이전 PRR 코멘트 삭제

`review.on_update` 가 `"review"` 인 경우에만 실행:
```bash
bash $PRR_DIR/scripts/delete_prr_comments.sh <REPO> <PR_NUMBER>
```

### Step 5 — 리뷰어별 리뷰 수행

각 enabled 리뷰어 JSON에서 읽는 필드:
- `comment_header` — 코멘트 제목 (예: "🌱 Junior Reviewer")
- `persona` — 리뷰어의 역할/관점
- `focus` — 중점 검토 항목 목록
- `ignore` — 검토 제외 항목 목록
- `severity_threshold` — 보고 최소 심각도 (`low` | `medium` | `high`)
- `lgtm_comment` — LGTM 시 코멘트 게시 여부 (boolean)

**리뷰 수행 지침:**
- `persona` 에 명시된 역할과 관점을 채택한다
- `focus` 항목들을 중심으로 diff를 꼼꼼히 검토한다
- `ignore` 항목들은 검토하지 않는다
- `severity_threshold` 미만의 이슈는 보고하지 않는다 (low < medium < high)
- 코드의 정확성, 보안, 안정성, 유지보수성을 우선 검토한다
- 근거 없는 단정 표현을 피한다. 증거가 약하면 추측임을 밝힌다

**이슈가 없는 경우:**
- `lgtm_comment: true` → 코멘트 게시
- `lgtm_comment: false` → 코멘트 생략

**이슈가 있는 경우 — 출력 형식:**
```
---
**파일명:줄번호**
심각도: low | medium | high
내용: (구체적인 문제 설명과 개선 제안)
---
```

### Step 6 — 코멘트 게시

코멘트 본문 구성:
```
<comment_header>

<리뷰 내용 또는 "특이사항 없음. LGTM ✓">

<!-- PRR-AUTO-REVIEW -->
```

게시:
```bash
gh pr comment <PR_NUMBER> --repo <REPO> --body "<코멘트 본문>"
```

여러 줄 본문은 임시 파일에 쓴 후 `--body-file` 로 전달한다:
```bash
TMPFILE=$(mktemp /tmp/prr_comment_XXXXXX)
# 본문을 TMPFILE에 기록
gh pr comment <PR_NUMBER> --repo <REPO> --body-file "$TMPFILE"
rm -f "$TMPFILE"
```

### Step 7 — 완료

"✓ PR #<PR_NUMBER> 리뷰 완료 (<N>개 리뷰어)" 출력
