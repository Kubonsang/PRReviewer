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
# comments 배열의 라인은 반드시 diff 범위 내 라인이어야 한다.

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

echo "$FINAL_JSON" | gh api "repos/$REPO/pulls/$PR_NUMBER/reviews" \
  --method POST --input -
echo "리뷰 게시 완료"
