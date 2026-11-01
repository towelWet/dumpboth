#!/usr/bin/env python3
# fix_jsonl_only.py — the ALWAYS-correctable orphan case: we already hold the jsonl,
# so dump/render.py can render the missing .md straight from it, no hunting needed.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
from pathlib import Path


def fix_jsonl_only(pairs: dict, old_chats_dir: str, root_dir: str) -> list[str]:  # ONE function
    root = Path(root_dir)
    target = Path(old_chats_dir).parent                  # render.py names folder holding Old Chats
    suggestions: list[str] = []
    for num in sorted(pairs):
        slot = pairs[num]
        if slot["md"] is not None or slot["jsonl"] is None:
            continue                                  # only the jsonl-only case
        # Use the EXISTING file's own stem (not a reconstructed one) so the fix always
        # matches literally, including a plain user suffix that isn't an 8-hex tag.
        stem = Path(slot["jsonl"]).stem
        md_path = str(Path(old_chats_dir) / f"{stem}.md")
        suggestions.append(
            f"oldchat{num}: jsonl-only, fillable now ->\n"
            f'  python3 "{root / "dump" / "render.py"}" "{root / "agents" / "claude"}" "{slot["jsonl"]}" "{target}" > "{md_path}"'
        )
    return suggestions
