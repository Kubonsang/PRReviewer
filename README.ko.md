# PRR — PR Auto Reviewer

GitHub Pull Request에 AI 리뷰어가 코멘트를 남기는 도구.
Claude Code 스킬로 동작하며, 유료 API 없이 ToS를 완전히 준수한다.

---

## 개요

- **AI 엔진**: AI 코딩 툴 스킬 (`/prr-scan`, `/prr-add-reviewer`, `/prr-review`, `/prr-followup`)
- **스킬 관리**: `prr` CLI (`skill sync`, `status`)
- **PR 연동**: `gh` CLI
- **비용**: 0원 (AI 코딩 툴 구독 범위 내)
- **ToS**: 사람이 직접 트리거 → Anthropic·GitHub ToS 완전 준수

리뷰어 페르소나를 JSON으로 정의하면 각자 별도의 GitHub 코멘트를 게시한다.
이슈는 해당 코드 라인에 인라인 코멘트로, 요약은 PR 코멘트로 분리해 게시한다.
한 리포에 주니어/시니어 등 여러 리뷰어를 설정할 수 있다.

설정 파일(`.prr/`)은 각 프로젝트 폴더에 저장된다.
스킬은 모두 **해당 프로젝트 디렉터리**에서 Claude Code를 열고 실행한다.

---

## 사전 요구사항

- [Claude Code](https://claude.ai/code) 설치 및 로그인
- [GitHub CLI](https://cli.github.com) 설치 및 인증 (`gh auth login`)
- Python 3.10+

---

## 설치

```bash
git clone https://github.com/Kubonsang/PRReviewer.git ~/PRR
echo 'export PATH="$PATH:$HOME/PRR"' >> ~/.zshrc
source ~/.zshrc
```

스킬 등록:

```bash
prr skill sync
```

환경 확인:

```bash
prr status
```

---

## 사용법

스킬은 리뷰할 **프로젝트 디렉터리**에서 Claude Code를 열고 실행한다.

### 1. 프로젝트 스캔 + 등록

프로젝트 루트에서 실행. `.prr/env.json` 자동 생성:

```
/prr-scan
```

### 2. 리뷰어 설정

AI가 프로젝트에 맞는 리뷰어를 추천한다:

```
/prr-add-reviewer
```

### 3. PR 리뷰

```
/prr-review 42
```

### 4. 팔로업 (선택)

수정 커밋 후 실행하면 반영된 이슈에 답글을 자동으로 게시한다:

```
/prr-followup 42
```

---

## CLI 커맨드

| 커맨드 | 설명 |
|--------|------|
| `prr skill sync` | 스킬 동기화 (git pull 후 실행) |
| `prr skill status` | 스킬 동기화 상태 확인 |
| `prr status` | 환경 상태 확인 (gh, python3) |

---

## 설정 파일

설정은 각 프로젝트 루트의 `.prr/` 디렉터리에 저장된다.

### `.prr/env.json`

리포 환경 정보 (`/prr-scan`이 자동 생성).

```json
{
  "repo": "owner/repo",
  "languages": ["TypeScript"],
  "framework": "Next.js 14",
  "key_dependencies": ["prisma", "zod"],
  "conventions": ["서버 컴포넌트 우선"],
  "review": {
    "exclude_paths": ["*.lock", "*.generated.ts"],
    "on_update": "skip"
  }
}
```

### `.prr/reviewers/{id}.json`

리뷰어 페르소나.

```json
{
  "id": "junior",
  "enabled": true,
  "comment_header": "🌱 Junior Reviewer",
  "persona": "당신은 1년차 주니어 개발자입니다.",
  "focus": ["로직 오류", "중복 코드"],
  "ignore": ["아키텍처 결정", "성능 최적화"],
  "severity_threshold": "low",
  "lgtm_comment": true,
  "tone": "친근하고 격려하는 말투. 동료 개발자를 응원하는 느낌으로.",
  "comment_sections": ["review_basis", "praise", "issues", "summary"]
}
```

`comment_sections` 옵션:
- `"review_basis"` — 집중 항목과 검토 제외 항목 요약
- `"praise"` — 잘 작성된 코드·패턴 언급 (없으면 섹션 생략)
- `"issues"` — 발견된 이슈 목록 (없으면 LGTM 메시지로 대체)
- `"summary"` — `tone`에 맞는 마무리 한마디

`tone`과 `comment_sections`는 선택 필드. 없으면 `["issues"]`와 중립 말투를 사용한다.

`on_update` 옵션:
- `"skip"` — 기존 PRR 코멘트 유지 (기본값)
- `"review"` — 이전 PRR 코멘트 삭제 후 재리뷰

---

## 라이선스

MIT
