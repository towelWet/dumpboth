#!/usr/bin/env python3
# fix_md_only.py — the CONDITIONALLY-correctable orphan case: an .md's "Source: <path>"
# footer (written by parse_session.py) may still point at a readable jsonl. If it
# does, filling the gap is a plain copy. If the source is gone, this is NOT the
# "easy" case the user asked for — skip it silently rather than suggesting a
# /find-claude-chat style hunt.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import re
from pathlib import Path

SOURCE_FOOTER_RE = re.compile(r"^Source: (.+)$", re.MULTILINE)


def fix_md_only(pairs: dict, old_chats_dir: str) -> list[str]:   # ONE function
    suggestions: list[str] = []
    for num in sorted(pairs):
        slot = pairs[num]
        if slot["jsonl"] is not None or slot["md"] is None:
            continue                                  # only the md-only case
        try:
            text = Path(slot["md"]).read_text(errors="ignore")
        except OSError:
            continue
        m = SOURCE_FOOTER_RE.search(text)
        if not m:
            continue
        source_path = Path(m.group(1).strip()).expanduser()
        if not source_path.is_file():
            continue                                  # source gone — not the easy case
        # Use the EXISTING .md's own stem (not a reconstructed one) so the fix always
        # matches literally, including a plain user suffix that isn't an 8-hex tag.
        stem = Path(slot["md"]).stem
        jsonl_path = str(Path(old_chats_dir) / f"{stem}.jsonl")
        suggestions.append(
            f"oldchat{num}: md-only, fillable now (source jsonl still exists) ->\n"
            f'  cp "{source_path}" "{jsonl_path}"'
        )
    return suggestions
