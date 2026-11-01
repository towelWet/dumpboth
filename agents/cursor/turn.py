#!/usr/bin/env python3
# turn.py — one Cursor record to (role, text).
# Why: text blocks print as-is; tool calls print as short summaries.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
from extract_user_text import extract_user_text
from summarize_tool import summarize_tool


def turn(record):
    role, message = record.get("role"), record.get("message") or {}
    content = message.get("content") if isinstance(message, dict) else None
    if role not in ("user", "assistant") or not isinstance(content, list):
        return None, None
    chunks = []
    for item in content:
        if isinstance(item, dict) and item.get("type") == "text" and item.get("text"):
            chunks.append(item["text"])
        elif isinstance(item, dict) and item.get("type") == "tool_use":
            chunks.append(summarize_tool(item))
    text = "\n\n".join(chunks)
    return role, extract_user_text(text) if role == "user" and text else text
