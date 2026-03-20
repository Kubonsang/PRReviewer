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

Claude Code 스킬 등록:

```bash
cp -r ~/PRR/skills/prr-review ~/.claude/skills/
cp -r ~/PRR/skills/prr-scan  ~/.claude/skills/
```

> **참고**: 스킬 파일(`~/.claude/skills/prr-*/SKILL.md`) 안의 `PRR_DIR` 경로를 실제 클론 경로로 수정해야 한다.
>
> ```bash
> # 클론 경로 확인
> which prr | xargs dirname
> ```

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

```bash
prr reviewer add owner/my-repo   # 새 리뷰어 추가
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
| `prr init <owner/repo>` | 리포 등록 |
| `prr reviewer add <owner/repo>` | 리뷰어 추가 |
| `prr reviewer list <owner/repo>` | 리뷰어 목록 |
| `prr repo list` | 등록된 리포 목록 |
| `prr status` | 환경 상태 확인 |

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
  "lgtm_comment": true
}
```

`on_update` 옵션:
- `"skip"` — 기존 PRR 코멘트 유지 (기본값)
- `"review"` — 이전 PRR 코멘트 삭제 후 재리뷰

---

## 라이선스

MIT
