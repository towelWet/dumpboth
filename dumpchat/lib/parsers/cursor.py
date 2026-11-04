#!/usr/bin/env python3
# lib/parsers/cursor.py — Cursor IDE agent JSONL parser
# NEVER DELETE COMMENTS — explain every non-obvious line. Update comments with the code.
import re

CLI_TYPE = "cursor"

_USER_QUERY_RE = re.compile(r"<user_query>\s*(.*?)\s*</user_query>", re.S)
_STRIP_TAGS_RE = re.compile(r"<[^>]+>")

def _extract_user_text(text):
    """Extract clean user text from Cursor's XML-wrapped user messages."""
    m = _USER_QUERY_RE.search(text)
    if m: return m.group(1).strip()
    cleaned = _STRIP_TAGS_RE.sub("", text).strip()
    return cleaned if cleaned else text.strip()

def _summarize_tool(item):
    """One-line summary of a tool_use block."""
    name = item.get("name", "unknown")
    inp = item.get("input") or {}
    if not isinstance(inp, dict): return f"Tool: {name}"
    if "command" in inp:
        cmd = str(inp["command"]).replace("\n", " ")
        return f"Tool: {name}\n{cmd[:140]}"
    if "path" in inp:
        extra = f" — {inp['description']}" if "description" in inp else ""
        return f"Tool: {name}\npath: {inp['path']}{extra}"
    return f"Tool: {name}"

def _flatten_content(content):
    """Extract text + tool summaries from content list."""
    if not isinstance(content, list): return []
    out = []
    for item in content:
        if not isinstance(item, dict): continue
        t = item.get("type")
        if t == "text" and item.get("text"): out.append(item["text"])
        elif t == "tool_use": out.append(_summarize_tool(item))
    return out

def parse(line_data):
    """Return (role, text) or (None, None) to skip."""
    if line_data.get("type") == "turn_ended": return None, None
    role = line_data.get("role")
    if role not in ("user", "assistant"): return None, None
    msg = line_data.get("message") or {}
    chunks = _flatten_content(msg.get("content") or [])
    if not chunks: return None, None
    combined = "\n\n".join(chunks)
    if role == "user": combined = _extract_user_text(combined)
    return role, combined
