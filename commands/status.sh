#!/usr/bin/env bash
set -euo pipefail

echo "=== PRR 환경 상태 ==="
echo ""

# gh CLI
printf "gh CLI:      "
if command -v gh &>/dev/null; then
  if gh auth status &>/dev/null 2>&1; then
    GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "알 수 없음")
    echo "✓ 인증됨 (@$GH_USER)"
  else
    echo "✗ 미인증"
    echo "  → gh auth login 을 실행하세요"
  fi
else
  echo "✗ 설치되지 않음"
  echo "  → brew install gh"
fi

# python3
printf "Python 3:    "
if command -v python3 &>/dev/null; then
  PYVER=$(python3 --version 2>&1 | awk '{print $2}')
  echo "✓ $PYVER"
else
  echo "✗ 설치되지 않음"
fi

echo ""

# 등록된 리포 수
REPO_COUNT=$(find "$PRR_DIR/configs/repos" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "등록된 리포: ${REPO_COUNT}개"

echo ""
echo "PRR 경로: $PRR_DIR"
echo ""
echo "PATH 등록 여부:"
if echo "$PATH" | tr ':' '\n' | grep -qF "$PRR_DIR"; then
  echo "  ✓ PATH에 등록됨"
else
  echo "  ✗ PATH에 없음"
  echo "  → ~/.zshrc 에 추가: export PATH=\"\$PATH:$PRR_DIR\""
fi
