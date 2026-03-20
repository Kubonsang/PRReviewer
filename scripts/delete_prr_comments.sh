#!/usr/bin/env bash
set -euo pipefail

REPO="${1:?}"
PR_NUMBER="${2:?}"

if [[ ! "$REPO" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
  echo "오류: 리포 형식이 올바르지 않습니다." >&2
  exit 1
fi
if [[ ! "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "오류: PR 번호는 숫자여야 합니다." >&2
  exit 1
fi

COMMENT_IDS=$(gh api "repos/$REPO/issues/$PR_NUMBER/comments" \
  --jq '.[] | select(.body | contains("<!-- PRR-AUTO-REVIEW -->")) | .id' 2>/dev/null || echo "")

if [[ -z "$COMMENT_IDS" ]]; then
  echo "  삭제할 PRR 코멘트 없음"
  exit 0
fi

while IFS= read -r ID; do
  [[ -z "$ID" ]] && continue
  gh api "repos/$REPO/issues/comments/$ID" -X DELETE 2>/dev/null
  echo "  코멘트 삭제: #$ID"
done <<< "$COMMENT_IDS"
