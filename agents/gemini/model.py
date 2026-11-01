#!/usr/bin/env python3
# model.py — model that answered first in this Gemini session.
# Why: header names real model; plain label when session has no answer yet.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import json
from extract_text import extract_text


def model(session_file):
    with open(session_file, encoding="utf-8", errors="replace") as f:
        for line in f:
            try:
                record = json.loads(line)
            except ValueError:
                continue
            if isinstance(record, dict) and record.get("type") in ("gemini", "assistant") and extract_text(record.get("content", "")):
                return record.get("model") or "Gemini CLI"
    return "Gemini CLI"
