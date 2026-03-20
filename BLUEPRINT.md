# PRR — PR Auto Reviewer Blueprint

## 개요

GitHub Pull Request에 AI 리뷰어가 자동으로 코멘트를 남기는 도구.
Claude Code 스킬을 AI 엔진으로 사용하며, 리포별·리뷰어별 커스터마이징을 지원한다.

---

## 핵심 제약

- **비용 0원** — 유료 API 없음, Claude Code 구독 범위 내 사용
- **ToS 준수** — 사람이 직접 트리거 (자동화 파이프라인 없음)
- **Private repo 포함** — gh CLI 인증으로 처리
- **기능 최소화** — 필요한 것만 구현

---

## 기술 스택

| 역할 | 도구 |
|------|------|
| AI 엔진 | Claude Code 스킬 (`/prr-review`, `/prr-scan`) |
| PR diff 수집 | `gh` CLI |
| 코멘트 게시 | `gh` CLI |
| 설정 관리 | `prr` CLI |

---

## 인터페이스

### CLI — 설정 관리 (`prr`)

```
prr init <owner/repo>            # 리포 등록 (설정 디렉터리 생성)
prr reviewer add <owner/repo>    # 리뷰어 추가 (인터랙티브)
prr reviewer list <owner/repo>   # 리뷰어 목록 출력
prr repo list                    # 등록된 리포 목록
prr skill sync                   # 스킬 동기화 (git pull 후 실행)
prr skill status                 # 스킬 동기화 상태 확인
prr status                       # 환경 상태 확인
```

### Claude Code 스킬 — AI 작업

```
/prr-scan <local-path> <owner/repo>   # 프로젝트 분석 → env.json 생성
/prr-add-reviewer <owner/repo>        # 리뷰어 후보 추천 → reviewer JSON 생성
/prr-review <owner/repo> <pr-number>  # PR 리뷰 실행 → GitHub 코멘트 게시
```

---

## 디렉터리 구조

```
PRR/
├── prr                              # CLI 진입점
│
├── commands/
│   ├── init.sh                      # prr init
│   ├── reviewer.sh                  # prr reviewer add/list
│   ├── repo.sh                      # prr repo list
│   └── status.sh                    # prr status
│
├── scripts/
│   ├── fetch_diff.sh                # gh pr diff 래퍼
│   ├── filter_diff.py               # exclude_paths 필터
│   ├── post_comment.sh              # GitHub 코멘트 게시 (PRR 마커 포함)
│   ├── delete_prr_comments.sh       # 이전 PRR 코멘트 삭제
│   └── notify.sh                    # macOS 데스크탑 알림
│
├── skills/
│   ├── prr-review/SKILL.md          # /prr-review 스킬 정의
│   ├── prr-scan/SKILL.md            # /prr-scan 스킬 정의
│   └── prr-add-reviewer/SKILL.md    # /prr-add-reviewer 스킬 정의
│
├── templates/
│   └── reviewer_default.json        # prr init 시 복사할 기본 리뷰어
│
└── configs/
    └── repos/
        └── {owner}__{repo}/         # /를 __로 치환
            ├── env.json
            └── reviewers/
                ├── junior.json
                └── senior.json
```

### Claude Code 스킬 등록

```bash
cp -r skills/prr-review       ~/.claude/skills/
cp -r skills/prr-scan         ~/.claude/skills/
cp -r skills/prr-add-reviewer ~/.claude/skills/
```

---

## 설정 파일 스키마

### `env.json` — 리포 환경 정보

```json
{
  "repo": "owner/repo-name",
  "languages": ["TypeScript", "CSS"],
  "runtime": "Node.js 20",
  "framework": "Next.js 14",
  "test_framework": "Jest",
  "linter": "ESLint (airbnb-typescript)",
  "key_dependencies": ["prisma", "zod", "tailwindcss"],
  "conventions": [
    "서버 컴포넌트 우선, use client 최소화",
    "함수형 컴포넌트만 사용"
  ],
  "review": {
    "exclude_paths": ["migrations/", "*.generated.ts", "public/", "*.lock"],
    "max_diff_lines": 500,
    "on_update": "skip"
  }
}
```

| `on_update` 값 | 동작 |
|---|---|
| `"skip"` | 이전 PRR 코멘트 유지 (기본값) |
| `"review"` | 이전 PRR 코멘트 삭제 후 새로 게시 |

### `reviewers/{id}.json` — 리뷰어 페르소나

```json
{
  "id": "junior",
  "enabled": true,
  "comment_header": "🌱 Junior Reviewer",
  "persona": "당신은 이제 막 팀에 합류한 1년차 주니어 개발자입니다.",
  "focus": [
    "변수명·함수명이 역할을 명확히 드러내는가",
    "명백한 로직 오류나 누락된 예외처리",
    "불필요한 중복 코드"
  ],
  "ignore": [
    "시스템 아키텍처 결정",
    "성능 최적화",
    "보안 취약점"
  ],
  "output_language": "ko",
  "severity_threshold": "low",
  "lgtm_comment": true,
  "tone": "친근하고 격려하는 말투. 동료 개발자를 응원하는 느낌으로.",
  "comment_sections": ["review_basis", "praise", "issues", "summary"]
}
```

| `comment_sections` 값 | 섹션 내용 |
|---|---|
| `"review_basis"` | 집중 항목(`focus`)과 검토 제외 항목(`ignore`) 요약 |
| `"praise"` | diff에서 잘 작성된 코드·패턴 언급 (없으면 섹션 생략) |
| `"issues"` | 발견된 이슈 목록 (없으면 LGTM 메시지로 대체) |
| `"summary"` | `tone`에 맞는 마무리 한마디 |

`tone`과 `comment_sections` 필드는 선택값이다. 없으면 `["issues"]` 기본값과 중립 말투를 사용한다.

---

## 워크플로우

### 최초 세팅

```
1. prr init owner/repo
   └─ configs/repos/owner__repo/ 생성
   └─ reviewers/junior.json 기본 템플릿 복사

2. /prr-scan ~/projects/my-repo owner/repo   (Claude Code에서 실행)
   └─ 프로젝트 파일 분석 → env.json 생성·저장

3. prr reviewer add owner/repo   (선택)
   └─ 추가 리뷰어 설정
```

### PR 리뷰 실행

```
/prr-review owner/repo 42         (Claude Code에서 실행)
├─ env.json 로드
├─ enabled 리뷰어 목록 수집
├─ gh pr diff 42 --repo owner/repo
├─ exclude_paths 필터링
├─ on_update=review 시 이전 PRR 코멘트 삭제
├─ [리뷰어 순회]
│   ├─ 페르소나 채택 → diff 검토
│   └─ gh pr comment → GitHub 코멘트 게시
└─ 완료 메시지
```

---

## 엣지케이스 처리

### 1. Diff가 클 때

- `env.json`의 `exclude_paths`로 불필요한 파일 사전 제거
- Claude Code는 대용량 컨텍스트를 네이티브로 처리

### 2. PR 업데이트(재푸시) 시

- `on_update: "skip"` — 이전 코멘트 유지 (기본)
- `on_update: "review"` — `<!-- PRR-AUTO-REVIEW -->` 마커로 이전 코멘트 식별 후 삭제, 재리뷰

### 3. LGTM (이상 없음)

리뷰어가 문제를 찾지 못한 경우 투명하게 코멘트 게시:

```
🌱 Junior Reviewer
특이사항 없음. LGTM ✓
<!-- PRR-AUTO-REVIEW -->
```

`lgtm_comment: false`로 설정 시 코멘트 생략.

### 4. 리뷰어 실패 시

macOS 데스크탑 알림으로 즉각 인지:
```bash
osascript -e 'display notification "리뷰 실패 — PR #42" \
  with title "PRR 오류" subtitle "owner/repo" sound name "Basso"'
```
