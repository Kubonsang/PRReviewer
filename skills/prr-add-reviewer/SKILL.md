---
name: prr-add-reviewer
description: PRR 리뷰어 추가 스킬. 사용자가 /prr-add-reviewer를 실행할 때 동작한다. 현재 디렉터리의 .prr/env.json을 읽어 맞춤형 리뷰어 후보를 추천하고, 사용자가 선택하면 페르소나·집중 항목·무시 항목을 자동 구성해 reviewer JSON을 생성·저장한다. prr-add-reviewer 또는 PRR 리뷰어 추가 요청이 있을 때 반드시 이 스킬을 사용한다.
---

## 변수
- `CONFIG_DIR` = `$(pwd)/.prr`
- `$CONFIG_DIR/env.json` 없으면 오류 후 종료

## 컨텍스트 파악
`env.json`에서 언어·프레임워크·의존성·컨벤션 파악. `reviewers/`에서 기존 id 수집.

## 리뷰어 후보 추천
프레임워크·의존성의 실제 리스크 기반으로 4–6개 추천 (단순 시니어/주니어 나열 금지).
기존 등록 id는 `(이미 등록됨)` 표시. 마지막에 "직접 입력" 옵션 추가.

## JSON 구성
| 필드 | 기준 |
|------|------|
| `id` | 선택한 id |
| `enabled` | `true` |
| `comment_header` | 이모지 + 영문 명칭 |
| `persona` | 역할·관점 1–2문장 (구체적일수록 품질↑) |
| `focus` | 놓치면 안 되는 검토 카테고리 3–5개 |
| `ignore` | 범위 밖 항목 2–4개 |
| `rules` | 위반 여부를 체크할 규칙 목록 (선택). 문자열 또는 `{rule, reason?, example?}` |
| `output_language` | `"ko"` |
| `severity_threshold` | junior→`"low"`, 전문가/시니어→`"medium"` |
| `lgtm_comment` | `true` |

**rules 작성 기준:** focus 범위 내 규칙만. 위반 조건을 명확히 서술 ("에러 처리 확인" ✗ → "async 함수에 try-catch 없으면 위반" ✓). env.json `conventions`·`key_dependencies` 참고.

JSON 출력 후 커스텀 rules 추가 여부를 물어본다. 사용자가 입력하면 추가, 엔터면 건너뜀.

확인 `[Y/n]` → 수정 요청 시 해당 부분만 수정 후 재출력. 확인 날 때까지 반복.

## 저장
같은 id 존재 시 덮어쓰기 경고. `$CONFIG_DIR/reviewers/{id}.json` 저장 (들여쓰기 2칸).

완료: `✓ 리뷰어 '{id}' 추가 완료` 출력. 다음 단계: `/prr-review <pr-number>`
