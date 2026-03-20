#!/usr/bin/env bash
set -euo pipefail

REPO="${1:?}"
PR_NUMBER="${2:?}"
BODY_FILE="${3:?}"

if [[ ! "$REPO" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
  echo "오류: 리포 형식이 올바르지 않습니다." >&2
  exit 1
fi
if [[ ! "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "오류: PR 번호는 숫자여야 합니다." >&2
  exit 1
fi
if [[ ! -f "$BODY_FILE" ]]; then
  echo "오류: 코멘트 파일이 없습니다: $BODY_FILE" >&2
  exit 1
fi

MARKED=$(mktemp /tmp/prr_comment_XXXXXX)
trap 'rm -f "$MARKED"' EXIT

cat "$BODY_FILE" > "$MARKED"
printf "\n<!-- PRR-AUTO-REVIEW -->\n" >> "$MARKED"

gh pr comment "$PR_NUMBER" --repo "$REPO" --body-file "$MARKED"
