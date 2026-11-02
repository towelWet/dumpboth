#!/usr/bin/env python3
# load_known_lost.py — read db/known-lost/<number>.toml markers into {number: reason}.
# WHY IT EXISTS: some orphans can never be fixed (source jsonl deleted). Each one is
# accepted by dropping a marker file — data, not code — so detect reports it as
# "accepted" instead of a live desync. Glob-discovered: add a gap = add a file.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

import tomllib                                       # stdlib TOML reader (py3.11+)
from pathlib import Path


def load_known_lost(db_dir: str) -> dict:             # ONE function, per /split-files
    lost: dict = {}
    for path in sorted(Path(db_dir, "known-lost").glob("*.toml")):
        if not path.stem.isdigit():
            continue                                 # marker name must be the dump number
        try:
            data = tomllib.loads(path.read_text())
        except (OSError, tomllib.TOMLDecodeError):
            continue                                 # unreadable marker: don't hide a real gap
        lost[int(path.stem)] = data.get("reason", "accepted (no reason given)")
    return lost
