#!/usr/bin/env python3
# turn.py — one Gemini CLI record to (role, text).
# Why: Gemini calls own turns gemini; $set and info records are metadata.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
from extract_text import extract_text

ROLES = {"user": "user", "gemini": "assistant", "assistant": "assistant"}


def turn(record):
    if "$set" in record or record.get("type") not in ROLES:
        return None, None
    return ROLES[record["type"]], extract_text(record.get("content", ""))
