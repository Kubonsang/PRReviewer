#!/usr/bin/env bash
set -euo pipefail

REPO="${1:?}"
PR_NUMBER="${2:?}"
REVIEWER_ID="${3:?}"
REASON="${4:?}"

if [[ ! "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "오류: PR 번호는 숫자여야 합니다." >&2
  exit 1
fi

# osascript 인젝션 방지: 외부 입력을 환경 변수로 전달하고 AppleScript에서 읽는다
PRR_NOTIF_TITLE="PRR 오류" \
PRR_NOTIF_SUBTITLE="$REPO" \
PRR_NOTIF_MSG="${REVIEWER_ID} 리뷰 실패 — PR #${PR_NUMBER}" \
osascript - <<'APPLESCRIPT' 2>/dev/null || true
set notifTitle to system attribute "PRR_NOTIF_TITLE"
set notifSubtitle to system attribute "PRR_NOTIF_SUBTITLE"
set notifMsg to system attribute "PRR_NOTIF_MSG"
display notification notifMsg with title notifTitle subtitle notifSubtitle sound name "Basso"
APPLESCRIPT
