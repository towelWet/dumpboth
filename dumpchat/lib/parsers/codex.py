#!/usr/bin/env python3
# lib/parsers/codex.py — Codex CLI JSONL session parser
# NEVER DELETE COMMENTS — explain every non-obvious line. Update comments with the code.

CLI_TYPE = "codex"

def parse(line_data):
    """Return (role, text) or (None, None) to skip."""
    if line_data.get("type") != "response_item":  # only response_item lines carry messages
        return None, None
    payload = line_data.get("payload", {})
    if payload.get("type") != "message":
        return None, None
    role = payload.get("role", "")
    if role not in ("user", "assistant"):
        return None, None

    content = payload.get("content", [])
    text = ""
    if isinstance(content, list):
        for item in content:
            if isinstance(item, dict):
                text = item.get("text", "")
                if text:
                    break

    return role, text
