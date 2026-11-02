#!/usr/bin/env python3
# lib/parsers/claude.py — Claude Code JSONL session parser
# NEVER DELETE COMMENTS — explain every non-obvious line. Update comments with the code.

CLI_TYPE = "claude"   # key used by parse_session.py for dynamic dispatch

def parse(line_data):
    """Return (role, text) or (None, None) to skip."""
    if line_data.get("isMeta"):                    # internal meta-lines, not conversation
        return None, None
    msg_type = line_data.get("type", "")
    if msg_type not in ("user", "assistant"):
        return None, None

    message = line_data.get("message", {})
    role = message.get("role", "")
    content = message.get("content", "")

    text = ""
    if isinstance(content, str):
        text = content
    elif isinstance(content, list):
        for item in content:                       # first text block wins
            if isinstance(item, dict) and item.get("type") == "text":
                text = item.get("text", "")
                break

    if text:
        if "<command-message>" in text or "<command-name>" in text:
            return None, None                      # skip skill-invocation stubs
        if text.strip().startswith("<system-reminder>"):
            return None, None                      # skip injected system context

    return role, text
