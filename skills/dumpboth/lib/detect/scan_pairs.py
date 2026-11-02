#!/usr/bin/env python3
# scan_pairs.py — group every oldchat*.md / oldchat*.jsonl in a dir by its number+tag.
# WHY IT EXISTS: the raw fact-gathering half of desync detection. Pure data in, pure
# dict out — no printing here, so report_desync.py can render it however's useful
# and other future tooling can reuse this scan without inheriting print side-effects.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

import re                                            # split "oldchat123-abcd1234.md" into parts
from pathlib import Path                             # directory scan

# Captures: number, optional "-tag" suffix (tag = the LAST hyphen-segment before the
# extension, which is what /dumpboth writes — a user suffix like "-my-label" has no
# such trailing 8-hex-char segment, so it won't false-positive as a tag).
FILENAME_RE = re.compile(r"^oldchat(\d+)(?:-(.+))?\.(md|jsonl)$")
TAG_RE = re.compile(r"^[0-9a-f]{8}$")                # /dumpboth tags are exactly 8 lowercase hex


def scan_pairs(old_chats_dir: str) -> dict:           # ONE function, per /split-files
    """Returns {number: {'md': path|None, 'jsonl': path|None,
                          'md_tag': str|None, 'jsonl_tag': str|None}}"""
    pairs: dict = {}
    root = Path(old_chats_dir)
    if not root.is_dir():
        return pairs

    for path in list(root.glob("oldchat*.md")) + list(root.glob("oldchat*.jsonl")):
        m = FILENAME_RE.match(path.name)
        if not m:
            continue                                 # non-conforming name — not our concern here
        num, suffix, ext = m.group(1), m.group(2), m.group(3)
        num = int(num)
        tag = suffix if suffix and TAG_RE.match(suffix) else None
        slot = pairs.setdefault(num, {"md": None, "jsonl": None, "md_tag": None, "jsonl_tag": None})
        slot[ext] = str(path)
        slot[f"{ext}_tag"] = tag

    return pairs
