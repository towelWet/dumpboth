#!/usr/bin/env python3
# model/detect_model.py — find model id of newest assistant message in Claude session JSONL.
# Why: dump header names the model that actually ran, read from session rather than assumed.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import json


def detect_model(path):
    """Scan JSONL for the last assistant message that carries a model field."""
    model = None
    try:
        with open(path, encoding="utf-8", errors="replace") as f:    # one bad byte must not lose the header
            for line in f:
                if '"model"' not in line:                            # fast pre-filter before full parse
                    continue
                try:
                    d = json.loads(line)
                except ValueError:                                   # partial last line of a live session
                    continue
                m = d.get("message") if isinstance(d, dict) else None
                if isinstance(m, dict) and m.get("role") == "assistant" and m.get("model"):   # string message: skip, keep scanning
                    model = m["model"]                               # keep overwriting: last seen = most recent
    except OSError:                                                  # unreadable file: header says plain "Claude"
        pass
    return model
