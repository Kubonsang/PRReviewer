#!/usr/bin/env bash
set -euo pipefail

REPO="${1:?사용법: prr init <owner/repo>}"

if [[ ! "$REPO" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
  echo "오류: 리포 형식이 올바르지 않습니다. (예: owner/repo)" >&2
  exit 1
fi

REPO_KEY="${REPO//\//__}"
CONFIG_DIR="$PRR_DIR/configs/repos/$REPO_KEY"

echo "=== PRR 리포 등록: $REPO ==="
echo ""

# 설정 디렉터리 생성
mkdir -p "$CONFIG_DIR/reviewers"

# 기본 리뷰어 템플릿 복사
if [[ -z "$(ls -A "$CONFIG_DIR/reviewers" 2>/dev/null)" ]]; then
  cp "$PRR_DIR/templates/reviewer_default.json" "$CONFIG_DIR/reviewers/junior.json"
  echo "기본 리뷰어 생성: reviewers/junior.json"
fi

echo ""
echo "✓ 등록 완료: $REPO"
echo ""
echo "다음 단계:"
echo "  1. Claude Code에서 아래 스킬을 실행해 env.json을 생성하세요:"
echo "       /prr-scan <프로젝트-로컬-경로> $REPO"
echo ""
echo "  2. 리뷰어를 추가하거나 수정하세요:"
echo "       prr reviewer add $REPO"
echo "       편집기로 직접 수정: $CONFIG_DIR/reviewers/junior.json"
echo ""
echo "  3. PR 리뷰 실행:"
echo "       /prr-review $REPO <pr-number>"
