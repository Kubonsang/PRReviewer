#!/usr/bin/env bash
set -euo pipefail

SUBCOMMAND="${1:-}"
CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"

case "$SUBCOMMAND" in
  sync)
    echo "스킬 동기화: $PRR_DIR/skills/ → $CLAUDE_SKILLS_DIR/"
    echo ""

    if [[ ! -d "$PRR_DIR/skills" ]]; then
      echo "오류: $PRR_DIR/skills 디렉터리가 없습니다." >&2
      exit 1
    fi

    mkdir -p "$CLAUDE_SKILLS_DIR"

    synced=0
    for skill_dir in "$PRR_DIR/skills"/*/; do
      skill_name="$(basename "$skill_dir")"
      target_dir="$CLAUDE_SKILLS_DIR/$skill_name"

      cp -r "$skill_dir" "$CLAUDE_SKILLS_DIR/"
      echo "  ✓ $skill_name"
      synced=$((synced + 1))
    done

    echo ""
    echo "${synced}개 스킬 동기화 완료."
    ;;

  status)
    echo "=== PRR 스킬 상태 ==="
    echo ""

    if [[ ! -d "$PRR_DIR/skills" ]]; then
      echo "오류: $PRR_DIR/skills 디렉터리가 없습니다." >&2
      exit 1
    fi

    for skill_dir in "$PRR_DIR/skills"/*/; do
      skill_name="$(basename "$skill_dir")"
      src="$skill_dir/SKILL.md"
      dst="$CLAUDE_SKILLS_DIR/$skill_name/SKILL.md"

      printf "  %-24s " "$skill_name"

      if [[ ! -f "$dst" ]]; then
        echo "✗ 미설치  → prr skill sync"
      elif diff -q "$src" "$dst" &>/dev/null; then
        echo "✓ 최신"
      else
        echo "! 변경됨  → prr skill sync"
      fi
    done

    echo ""
    ;;

  *)
    echo "사용법: prr skill <서브커맨드>"
    echo ""
    echo "서브커맨드:"
    echo "  sync     프로젝트 스킬을 ~/.claude/skills/ 에 동기화"
    echo "  status   설치된 스킬과 프로젝트 스킬의 동기화 상태 확인"
    ;;
esac
