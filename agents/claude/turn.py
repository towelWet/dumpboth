#!/usr/bin/env python3
# turn.py — one Claude Code record to (role, text).
# Why: skips internal meta lines, skill stubs, and injected system context.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
SKIP_ANYWHERE = ("<command-message>", "<command-name>")         # skill-invocation stubs


def turn(record):
    message = record.get("message")
    if record.get("isMeta") or record.get("type") not in ("user", "assistant") or not isinstance(message, dict):
        return None, None
    content, text = message.get("content", ""), ""
    if isinstance(content, str):
        text = content
    elif isinstance(content, list):
        text = next((b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text"), "")   # first text block wins
    if any(tag in text for tag in SKIP_ANYWHERE) or text.strip().startswith("<system-reminder>"):
        return None, None
    return message.get("role", ""), text
