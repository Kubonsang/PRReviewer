#!/usr/bin/env bash
set -euo pipefail

# post_review.sh <owner/repo> <pr_number> <review_json_file>
#
# review_json_file 구조:
# {
#   "body": "요약 코멘트 본문",
#   "comments": [
#     { "path": "src/foo.ts", "line": 42, "side": "RIGHT", "body": "인라인 코멘트" },
#     ...
#   ]
# }
#
# 스크립트가 commit_id와 event를 자동으로 주입한 뒤 GitHub Reviews API로 게시한다.
# 인라인 코멘트 게시 실패 시 (라인이 diff 범위 밖 등) 해당 항목을 요약 본문에 병합해
# 일반 PR 코멘트로 폴백한다.

REPO="${1:?리포 인수가 필요합니다 (owner/repo)}"
PR_NUMBER="${2:?PR 번호 인수가 필요합니다}"
REVIEW_FILE="${3:?리뷰 JSON 파일 경로가 필요합니다}"

# 입력 검증
if [[ ! "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "오류: PR 번호는 숫자여야 합니다." >&2
  exit 1
fi

if [[ ! "$REPO" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
  echo "오류: 리포 형식이 잘못됐습니다. (owner/repo)" >&2
  exit 1
fi

if [[ ! -f "$REVIEW_FILE" ]]; then
  echo "오류: 리뷰 파일이 없습니다: $REVIEW_FILE" >&2
  exit 1
fi

# PR 최신 커밋 SHA 조회
COMMIT_SHA=$(gh api "repos/$REPO/pulls/$PR_NUMBER" --jq '.head.sha')

# commit_id, event 주입
FINAL_JSON=$(python3 - "$REVIEW_FILE" "$COMMIT_SHA" <<'PYEOF'
import json, sys

review_file = sys.argv[1]
commit_sha  = sys.argv[2]

with open(review_file) as f:
    review = json.load(f)

review["commit_id"] = commit_sha
review["event"]     = "COMMENT"

print(json.dumps(review))
PYEOF
)

# GitHub Reviews API로 게시 시도
if echo "$FINAL_JSON" | gh api "repos/$REPO/pulls/$PR_NUMBER/reviews" \
    --method POST --input - > /dev/null 2>&1; then
  echo "리뷰 게시 완료 (인라인 코멘트 포함)"
  exit 0
fi

# 폴백: 인라인 코멘트를 요약 본문에 병합해 일반 PR 코멘트로 게시
echo "인라인 코멘트 게시 실패. 일반 코멘트로 폴백합니다." >&2

FALLBACK_BODY=$(python3 - "$REVIEW_FILE" <<'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    review = json.load(f)

body = review.get("body", "")
comments = review.get("comments", [])

if comments:
    body += "\n\n### 🔧 개선 제안\n"
    for c in comments:
        body += f"\n#### `{c['path']}:{c['line']}`\n{c['body']}\n"

print(body)
PYEOF
)

TMPFILE=$(mktemp /tmp/prr_comment_XXXXXX)
trap 'rm -f "$TMPFILE"' EXIT
echo "$FALLBACK_BODY" > "$TMPFILE"
gh pr comment "$PR_NUMBER" --repo "$REPO" --body-file "$TMPFILE"
echo "일반 코멘트로 게시 완료"
