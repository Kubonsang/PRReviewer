## Working Rules for Claude Code

- Prefer preserving the existing CLI-first architecture. New features should be exposed through `prr` subcommands, not ad-hoc scripts.
- Keep `commands/` thin and orchestration-focused; place reusable logic in `scripts/`.
- Do not rename or silently repurpose existing config keys in `env.json` or reviewer files without updating all callers.
- Favor backward-compatible config changes. New fields should be optional unless a migration path is added.
- When changing shell scripts, prefer safe Bash practices (`set -euo pipefail`) and quote all path variables.
- When changing Python scripts, keep dependencies minimal and prefer the standard library unless a strong reason exists.
- Use repo-root-relative path handling consistently; avoid assumptions based on the current working directory.
- Preserve file-level diff splitting behavior unless the design in `BLUEPRINT.md` is explicitly updated.

## Environment Assumptions

This project assumes:

- `gh` CLI is installed and already authenticated
- `python3` is available for helper scripts (`filter_diff.py`)
- Claude Code is the AI engine, invoked via skills (`/prr-review`, `/prr-scan`)
- macOS may be present for `notify.sh` (`osascript`), so avoid breaking macOS-specific behavior

If adding portability improvements, keep current macOS behavior working.

## Config Contract

`env.json` and reviewer JSON files are core interfaces. When editing code that reads or writes them:

- document new fields clearly
- preserve unknown fields when possible
- avoid destructive rewrites of user-maintained JSON
- provide sensible defaults for optional fields

Preferred behavior:
- missing optional field → apply default
- missing required field → fail with a clear error message

## Review Output Guidelines

Generated review comments should:

- prioritize correctness, security, reliability, and maintainability
- avoid nitpicks unless they materially affect readability or consistency
- be specific and actionable
- avoid confident claims when evidence is weak
- use `LGTM` only when no meaningful issues were found and the reviewer config allows LGTM comments

## Error Handling

- Never print secrets, tokens, auth state, or sensitive local machine details into PR comments.
- User-facing PR error comments should be brief and safe.
- Put detailed diagnostics in local logs/console output, not in PR comments.
- On partial failure, identify which reviewer failed and continue other reviewers when safe.

## Non-Goals

Unless explicitly requested by the user or design docs, do not:

- add automated triggering (GitHub Actions, webhooks, cron) — human trigger is intentional
- replace Claude Code skills with a paid API integration
- redesign the project into a server-based service
- collapse reviewer personas into a single generic reviewer