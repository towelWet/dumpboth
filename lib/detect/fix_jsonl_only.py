#!/usr/bin/env python3
# fix_jsonl_only.py — the ALWAYS-correctable orphan case: we already hold the jsonl,
# so parse_session.py can render the missing .md straight from it, no hunting needed.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
from pathlib import Path


def fix_jsonl_only(pairs: dict, old_chats_dir: str, dumpchat_lib_dir: str) -> list[str]:  # ONE function
    parse_session_py = str(Path(dumpchat_lib_dir) / "parse_session.py")
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
            f'  python3 "{parse_session_py}" "{slot["jsonl"]}" claude "{old_chats_dir}" > "{md_path}"'
        )
    return suggestions
