#!/usr/bin/env python3
# turn.py — one Codex rollout record to (role, text).
# Why: chat lives in response_item messages; user messages also carry injected context.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
INJECTED_TAGS = ("<environment_context>", "<instructions>", "<system-reminder>", "<external_codex_")
INJECTED_STARTS = ("# AGENTS.md", "# Codex Global")


def turn(record):
    payload = record.get("payload")
    if record.get("type") != "response_item" or not isinstance(payload, dict) or payload.get("type") != "message":
        return None, None
    role, content = payload.get("role"), payload.get("content")
    if role not in ("user", "assistant") or not isinstance(content, list):
        return None, None
    text = "\n\n".join(b["text"] for b in content if isinstance(b, dict) and isinstance(b.get("text"), str) and b["text"])
    stripped = text.strip()
    if role == "user" and (any(tag in stripped.lower() for tag in INJECTED_TAGS) or stripped.startswith(INJECTED_STARTS)):
        return None, None
    return role, text
