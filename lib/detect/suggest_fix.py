#!/usr/bin/env python3
# suggest_fix.py — thin combiner: runs both correctable-orphan checks and merges
# their suggestions. Kept deliberately tiny — all real logic lives in
# fix_jsonl_only.py and fix_md_only.py, one concern per file.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from fix_jsonl_only import fix_jsonl_only            # noqa: E402
from fix_md_only import fix_md_only                  # noqa: E402


def suggest_fix(pairs: dict, old_chats_dir: str, dumpchat_lib_dir: str) -> list[str]:  # ONE function
    return fix_jsonl_only(pairs, old_chats_dir, dumpchat_lib_dir) + fix_md_only(pairs, old_chats_dir)


if __name__ == "__main__":                            # python3 suggest_fix.py <old_chats_dir> <dumpchat_lib_dir>
    from scan_pairs import scan_pairs
    pairs = scan_pairs(sys.argv[1])
    for line in suggest_fix(pairs, sys.argv[1], sys.argv[2]):
        print(line)
