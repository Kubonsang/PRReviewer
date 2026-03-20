#!/usr/bin/env bash
set -euo pipefail

# post_reply.sh <owner/repo> <comment_id> <reply_body_file>
#
# GitHub PR review comment 에 답글을 게시한다.
# comment_id: gh api .../pulls/{n}/comments 에서 얻은 숫자 ID

REPO="${1:?리포 인수가 필요합니다 (owner/repo)}"
COMMENT_ID="${2:?코멘트 ID 인수가 필요합니다}"
BODY_FILE="${3:?본문 파일 경로가 필요합니다}"

if [[ ! "$COMMENT_ID" =~ ^[0-9]+$ ]]; then
  echo "오류: 코멘트 ID는 숫자여야 합니다." >&2
  exit 1
fi

if [[ ! "$REPO" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
  echo "오류: 리포 형식이 잘못됐습니다. (owner/repo)" >&2
  exit 1
fi

if [[ ! -f "$BODY_FILE" ]]; then
  echo "오류: 본문 파일이 없습니다: $BODY_FILE" >&2
  exit 1
fi

BODY_JSON=$(python3 -c "
import json, sys
print(json.dumps({'body': sys.stdin.read()}))
" < "$BODY_FILE")

echo "$BODY_JSON" | gh api "repos/$REPO/pulls/comments/$COMMENT_ID/replies" \
  --method POST \
  --input -
