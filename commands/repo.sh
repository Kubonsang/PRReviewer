#!/usr/bin/env bash
set -euo pipefail

SUBCOMMAND="${1:-list}"

case "$SUBCOMMAND" in
  list)
    REPOS_DIR="$PRR_DIR/configs/repos"
    if [[ ! -d "$REPOS_DIR" ]] || [[ -z "$(ls -A "$REPOS_DIR" 2>/dev/null)" ]]; then
      echo "등록된 리포가 없습니다."
      echo "  prr init <owner/repo> <local-path> 로 추가하세요."
      exit 0
    fi

    echo "등록된 리포:"
    for DIR in "$REPOS_DIR"/*/; do
      [[ -d "$DIR" ]] || continue
      REPO_KEY=$(basename "$DIR")
      REPO="${REPO_KEY//__//}"
      REVIEWER_COUNT=$(find "$DIR/reviewers" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
      ENABLED_COUNT=$(grep -l '"enabled": true' "$DIR/reviewers/"*.json 2>/dev/null | wc -l | tr -d ' ')
      echo "  $REPO  (리뷰어: ${ENABLED_COUNT}/${REVIEWER_COUNT})"
    done
    ;;
  *)
    echo "오류: 알 수 없는 서브커맨드 '$SUBCOMMAND'" >&2
    echo "사용법: prr repo list" >&2
    exit 1
    ;;
esac
