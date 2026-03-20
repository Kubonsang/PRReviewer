---
name: prr-followup
description: PRR 팔로업 리뷰어. 사용자가 /prr-followup <owner/repo> <pr-number>를 실행할 때 동작한다. 이전 PRR 인라인 코멘트에서 지적한 이슈가 새 커밋에서 수정됐는지 확인하고, 수정이 확인된 코멘트에 답글을 자동으로 게시한다. prr-followup 또는 PR 리뷰 팔로업, 수정 확인 관련 요청이 있을 때 반드시 이 스킬을 사용한다.
---

# PRR — 팔로업 리뷰어

## 트리거
사용자가 `/prr-followup <owner/repo> <pr-number>` 를 실행할 때 동작한다.
예: `/prr-followup myorg/backend 42`

PR 작성자가 리뷰 코멘트를 반영한 커밋을 올린 뒤 실행한다.

## PRR 설정 경로
PRR_DIR 은 사용자가 PRR을 클론한 경로다.
```bash
which prr | xargs dirname
```

## 실행 절차

### Step 1 — 인수 파싱
- REPO = 첫 번째 인수 (형식: `owner/repo`)
- PR_NUMBER = 두 번째 인수 (숫자)
- REPO_SLUG = REPO에서 `/`를 `__`로 치환
- CONFIG_DIR = `$PRR_DIR/configs/repos/$REPO_SLUG`

`$CONFIG_DIR/env.json` 이 없으면: "오류: 등록된 리포가 아닙니다." 출력 후 종료.

### Step 2 — 기존 PRR 인라인 코멘트 수집

PR의 모든 review comment를 가져온다:
```bash
gh api repos/<REPO>/pulls/<PR_NUMBER>/comments --paginate
```

`<!-- PRR-INLINE -->` 마커가 포함된 코멘트만 필터링한다. 각 코멘트에서 추출:
- `id` — 답글 게시 시 사용
- `path` — 파일 경로
- `line` — 라인 번호
- `body` — 이슈 설명 (수정 여부 판단에 사용)
- `in_reply_to_id` — 최상위 코멘트만 처리 (이 필드가 없는 것)

PRR 인라인 코멘트가 없으면: "이전 PRR 인라인 코멘트가 없습니다." 출력 후 종료.

### Step 3 — 이미 답글 달린 코멘트 제외

전체 코멘트 중 `in_reply_to_id` 가 있고 `<!-- PRR-FOLLOWUP -->` 마커를 포함한 것을 수집한다.
이미 팔로업 답글이 달린 PRR 코멘트는 처리 대상에서 제외한다.

### Step 4 — 현재 diff 수집

```bash
gh pr diff <PR_NUMBER> --repo <REPO>
```

### Step 5 — 이슈별 수정 여부 판단

각 미처리 PRR 인라인 코멘트에 대해:

1. 코멘트의 `path`와 `body`(이슈 내용)를 파악한다
2. 현재 diff에서 해당 파일의 변경사항을 확인한다
3. 아래 기준으로 수정 여부를 판단한다:

| 신호 | 판단 |
|------|------|
| 코멘트가 가리킨 라인이 삭제되거나 다른 코드로 교체됨 | 수정됨 가능성 높음 |
| 코멘트에서 제안한 방식이 새 diff에 반영됨 | 수정됨 |
| 해당 파일 자체에 변경 없음 | 건너뜀 |
| 변경됐지만 이슈와 무관한 수정 | 건너뜀 |

판단이 불명확하면 건너뛴다. 오탐보다 미탐이 낫다.

### Step 6 — 답글 게시

수정이 확인된 코멘트마다 답글을 게시한다.

**답글 형식:**
```markdown
✅ 수정이 반영됐습니다!

{어떻게 수정됐는지 구체적으로 한두 문장. 원래 이슈 해결 방식을 간략히 확인.}

<!-- PRR-FOLLOWUP -->
```

게시:
```bash
TMPFILE=$(mktemp /tmp/prr_reply_XXXXXX)
trap 'rm -f "$TMPFILE"' EXIT
# 답글 본문을 TMPFILE에 기록
bash "$PRR_DIR/scripts/post_reply.sh" "<REPO>" "<COMMENT_ID>" "$TMPFILE"
```

### Step 7 — 완료

수정된 항목이 있으면:
`"✓ PR #<PR_NUMBER> 팔로업 완료 — <전체>건 중 <수정확인>건 수정 확인"` 출력

수정된 항목이 없으면:
`"수정된 항목이 없습니다. 이전 PRR 코멘트가 유지됩니다."` 출력
