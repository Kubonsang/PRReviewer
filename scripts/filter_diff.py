#!/usr/bin/env python3
"""exclude_paths 패턴에 맞는 파일을 diff에서 제거한다."""
import sys
import re
import json
import fnmatch


def main() -> None:
    if len(sys.argv) != 3:
        print("사용법: filter_diff.py <diff.patch> <env.json>", file=sys.stderr)
        sys.exit(1)

    diff_path, env_path = sys.argv[1], sys.argv[2]

    with open(diff_path) as f:
        raw = f.read()

    with open(env_path) as f:
        env = json.load(f)

    exclude_paths = env.get("review", {}).get("exclude_paths", [])

    if not exclude_paths:
        print(raw, end="")
        return

    chunks = re.split(r"(?=^diff --git )", raw, flags=re.MULTILINE)
    kept = []
    skipped = 0

    for chunk in chunks:
        if not chunk.strip():
            continue

        match = re.match(r"diff --git a/(.+?) b/", chunk)
        if not match:
            kept.append(chunk)
            continue

        filename = match.group(1)
        skip = False

        for pattern in exclude_paths:
            if (
                fnmatch.fnmatch(filename, pattern)
                or fnmatch.fnmatch(filename, f"*/{pattern}")
                or filename.startswith(pattern.rstrip("/") + "/")
            ):
                skip = True
                break

        if skip:
            skipped += 1
        else:
            kept.append(chunk)

    if skipped > 0:
        print(f"  {skipped}개 파일 제외됨 (exclude_paths)", file=sys.stderr)

    print("".join(kept), end="")


if __name__ == "__main__":
    main()
