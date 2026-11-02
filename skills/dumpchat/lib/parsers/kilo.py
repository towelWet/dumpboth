#!/usr/bin/env python3
# lib/parsers/kilo.py — Kilo Code + OpenCode JSONL session parser (shared format)
# NEVER DELETE COMMENTS — explain every non-obvious line. Update comments with the code.
# OpenCode uses the same hierarchical JSON shape, so one parser handles both.

CLI_TYPE = "kilo"
ALSO_HANDLES = ("opencode",)   # parse_session.py registers this parser for both keys

def parse(line_data):
    """Return (role, text) or (None, None) to skip."""
    role = line_data.get("role", "")
    if role in ("user", "assistant"):
        return _extract(role, line_data.get("content", ""))

    # Nested message format fallback
    msg = line_data.get("message", {})
    if msg:
        return _extract(msg.get("role", ""), msg.get("content", ""))

    return None, None

def _extract(role, content):
    """Pull text from str or list[{text}] content shape."""
    if role not in ("user", "assistant"):
        return None, None
    text = ""
    if isinstance(content, str):
        text = content
    elif isinstance(content, list):
        for item in content:
            if isinstance(item, dict) and "text" in item:
                text = item["text"]
                break
    return role, text
