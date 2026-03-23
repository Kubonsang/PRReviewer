---
name: prr-followup
description: PRR 팔로업 리뷰어. 사용자가 /prr-followup <pr-number>를 실행할 때 동작한다. 이전 PRR 인라인 코멘트에서 지적한 이슈가 새 커밋에서 수정됐는지 확인하고, 수정이 확인된 코멘트에 답글을 자동으로 게시한다. prr-followup 또는 PR 리뷰 팔로업, 수정 확인 관련 요청이 있을 때 반드시 이 스킬을 사용한다.
---

## 변수
- `PR_NUMBER` = 첫 번째 인수
- `CONFIG_DIR` = `$(pwd)/.prr`
- `PRR_DIR` = `$(which prr | xargs dirname)`
- `REPO` = `gh repo view --json nameWithOwner --jq '.nameWithOwner'` — 비어있으면 오류 후 종료
- `$CONFIG_DIR/env.json` 없으면 오류 후 종료

## PRR 인라인 코멘트 수집
`gh api repos/<REPO>/pulls/<PR_NUMBER>/comments --paginate`
→ `<!-- PRR-INLINE -->` 마커 포함 코멘트만 필터링 (`in_reply_to_id` 없는 최상위만)
→ 각 코멘트에서 `id`, `path`, `line`, `body` 추출
→ 없으면 "이전 PRR 인라인 코멘트가 없습니다." 후 종료

`in_reply_to_id` 있고 `<!-- PRR-FOLLOWUP -->` 포함한 답글의 부모 코멘트는 처리 제외.

## 수정 여부 판단
`gh pr diff <PR_NUMBER> --repo <REPO>` 수집 후 각 코멘트의 `path`·`body` 기준으로 판단:
- 지적 라인이 삭제·교체됨 → 수정됨
- 제안한 방식이 새 diff에 반영됨 → 수정됨
- 파일 변경 없음 또는 이슈와 무관한 수정 → 건너뜀
- 불명확 → 건너뜀 (오탐 방지)

## 답글 게시
```
✅ 수정이 반영됐습니다!

{어떻게 수정됐는지 한두 문장.}

<!-- PRR-FOLLOWUP -->
```
```bash
TMPFILE=$(mktemp /tmp/prr_reply_XXXXXX)
trap 'rm -f "$TMPFILE"' EXIT
bash "$PRR_DIR/scripts/post_reply.sh" "<REPO>" "<COMMENT_ID>" "$TMPFILE"
```

완료: 수정 있으면 `✓ PR #N 팔로업 완료 — X건 중 Y건 수정 확인`, 없으면 `수정된 항목이 없습니다.`
