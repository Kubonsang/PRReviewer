# PRR — PR Auto Reviewer

GitHub Pull Request에 AI 리뷰어가 코멘트를 남기는 도구.
Claude Code 스킬로 동작하며, 유료 API 없이 ToS를 완전히 준수한다.

---

## 개요

- **AI 엔진**: Claude Code 스킬 (`/prr-review`, `/prr-scan`)
- **설정 관리**: `prr` CLI
- **PR 연동**: `gh` CLI
- **비용**: 0원 (Claude Code 구독 범위 내)
- **ToS**: 사람이 직접 트리거 → Consumer ToS 완전 준수

리뷰어 페르소나를 JSON으로 정의하면 각자 별도의 GitHub 코멘트를 게시한다.
한 리포에 주니어/시니어 등 여러 리뷰어를 설정할 수 있다.

---

## 사전 요구사항

- [Claude Code](https://claude.ai/code) 설치 및 로그인
- [GitHub CLI](https://cli.github.com) 설치 및 인증 (`gh auth login`)
- Python 3.10+

---

## 설치

```bash
git clone https://github.com/<your-username>/PRR.git ~/PRR
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

### 1. 리포 등록

```bash
prr init owner/my-repo
```

### 2. 프로젝트 스캔 (env.json 자동 생성)

Claude Code에서 실행:

```
/prr-scan ~/projects/my-repo owner/my-repo
```

### 3. 리뷰어 설정 (선택)

Claude Code에서 실행 (AI가 프로젝트에 맞는 리뷰어를 추천):

```
/prr-add-reviewer owner/my-repo
```

또는 CLI로 직접 추가:

```bash
prr reviewer add owner/my-repo   # 템플릿 복사 후 에디터로 편집
prr reviewer list owner/my-repo  # 목록 확인
```

### 4. PR 리뷰

Claude Code에서 실행:

```
/prr-review owner/my-repo 42
```

---

## CLI 커맨드

| 커맨드 | 설명 |
|--------|------|
| `prr init <owner/repo>` | 리포 등록 (설정 디렉터리 생성) |
| `prr skill sync` | 스킬 동기화 (git pull 후 실행) |
| `prr skill status` | 스킬 동기화 상태 확인 |
| `prr status` | 환경 상태 확인 (gh, python3) |

---

## 설정 파일

### `configs/repos/{owner}__{repo}/env.json`

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

### `configs/repos/{owner}__{repo}/reviewers/{id}.json`

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
