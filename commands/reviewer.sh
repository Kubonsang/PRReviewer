#!/usr/bin/env bash
set -euo pipefail

SUBCOMMAND="${1:-list}"
REPO="${2:?사용법: prr reviewer <add|list> <owner/repo>}"

if [[ ! "$REPO" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
  echo "오류: 리포 형식이 올바르지 않습니다. (예: owner/repo)" >&2
  exit 1
fi

REPO_KEY="${REPO//\//__}"
CONFIG_DIR="$PRR_DIR/configs/repos/$REPO_KEY"

if [[ ! -d "$CONFIG_DIR" ]]; then
  echo "오류: 리포 '$REPO' 설정을 찾을 수 없습니다." >&2
  echo "  먼저 'prr init $REPO <local-path>'를 실행하세요." >&2
  exit 1
fi

case "$SUBCOMMAND" in
  add)
    echo "새 리뷰어 추가: $REPO"
    echo ""
    printf "리뷰어 ID (영문, 하이픈 허용, 예: senior): "
    read -r REVIEWER_ID

    if [[ ! "$REVIEWER_ID" =~ ^[a-z0-9-]+$ ]]; then
      echo "오류: ID는 영소문자, 숫자, 하이픈만 사용할 수 있습니다." >&2
      exit 1
    fi

    TARGET="$CONFIG_DIR/reviewers/$REVIEWER_ID.json"

    if [[ -f "$TARGET" ]]; then
      printf "리뷰어 '$REVIEWER_ID'가 이미 존재합니다. 덮어쓸까요? [y/N] "
      read -r CONFIRM
      [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]] || exit 0
    fi

    cp "$PRR_DIR/templates/reviewer_default.json" "$TARGET"

    # ID, header 업데이트 — 환경 변수로 전달해 인젝션 방지
    PRR_TARGET="$TARGET" PRR_REVIEWER_ID="$REVIEWER_ID" python3 -c "
import json, os
path = os.environ['PRR_TARGET']
rid  = os.environ['PRR_REVIEWER_ID']
with open(path) as f:
    d = json.load(f)
d['id'] = rid
d['comment_header'] = f'🤖 {rid} Reviewer'
with open(path, 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
"
    echo "파일이 생성되었습니다: $TARGET"
    echo "에디터로 페르소나와 규칙을 수정하세요."
    echo ""

    EDITOR="${EDITOR:-vi}"
    printf "지금 에디터로 열까요? [Y/n] "
    read -r OPEN
    if [[ "$OPEN" != "n" && "$OPEN" != "N" ]]; then
      "$EDITOR" "$TARGET"
    fi

    echo "리뷰어 '$REVIEWER_ID' 추가 완료"
    ;;

  list)
    REVIEWERS_DIR="$CONFIG_DIR/reviewers"
    if [[ ! -d "$REVIEWERS_DIR" ]] || [[ -z "$(ls -A "$REVIEWERS_DIR" 2>/dev/null)" ]]; then
      echo "$REPO 에 등록된 리뷰어가 없습니다."
      exit 0
    fi

    echo "$REPO 리뷰어 목록:"
    for FILE in "$REVIEWERS_DIR"/*.json; do
      [[ -f "$FILE" ]] || continue
      # 파일 경로를 환경 변수로 전달해 인젝션 방지
      PRR_REVIEWER_FILE="$FILE" python3 -c "
import json, os
with open(os.environ['PRR_REVIEWER_FILE']) as f:
    d = json.load(f)
enabled = '✓' if d.get('enabled', True) else '✗'
print(f\"  {enabled} {d.get('id','?'):15} {d.get('comment_header','')}\")
"
    done
    ;;

  *)
    echo "오류: 알 수 없는 서브커맨드 '$SUBCOMMAND'" >&2
    echo "사용법: prr reviewer <add|list> <owner/repo>" >&2
    exit 1
    ;;
esac
