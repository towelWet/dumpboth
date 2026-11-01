#!/usr/bin/env python3
# read_turns.py — read session JSONL into (role, text) turns using agent's turn function.
# Why: skips blank and half-written lines, because live sessions end mid-write.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import json


def read_turns(session_file, turn):
    with open(session_file, encoding="utf-8", errors="replace") as f:
        for line in f:
            if not line.strip():
                continue
            try:
                record = json.loads(line)
            except ValueError:
                continue
            role, text = turn(record) if isinstance(record, dict) else (None, None)
            if role and text:
                yield role, text
