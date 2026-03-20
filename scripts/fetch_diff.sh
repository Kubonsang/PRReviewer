#!/usr/bin/env bash
set -euo pipefail

REPO="${1:?}"
PR_NUMBER="${2:?}"
ENV_JSON="${3:?}"
OUTPUT="${4:?}"

if [[ ! "$REPO" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
  echo "오류: 리포 형식이 올바르지 않습니다." >&2
  exit 1
fi
if [[ ! "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "오류: PR 번호는 숫자여야 합니다." >&2
  exit 1
fi

gh pr diff "$PR_NUMBER" --repo "$REPO" > "$OUTPUT.raw" 2>/dev/null || true

if [[ ! -s "$OUTPUT.raw" ]]; then
  touch "$OUTPUT"
  rm -f "$OUTPUT.raw"
  exit 0
fi

python3 "$PRR_DIR/scripts/filter_diff.py" "$OUTPUT.raw" "$ENV_JSON" > "$OUTPUT"
rm -f "$OUTPUT.raw"
