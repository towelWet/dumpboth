#!/usr/bin/env python3
# lib/parsers/gemini.py — Gemini CLI JSONL session parser
# NEVER DELETE COMMENTS — explain every non-obvious line. Update comments with the code.

CLI_TYPE = "gemini"

def parse(line_data):
    """Return (role, text) or (None, None) to skip."""
    if "$set" in line_data or (  # skip Firestore-style meta/setup lines
            "sessionId" in line_data and "type" not in line_data):
        return None, None

    msg_type = line_data.get("type", "")

    if msg_type == "user":
        content = line_data.get("content", [])
        text = ""
        if isinstance(content, list):
            for item in content:
                if isinstance(item, dict):
                    text = item.get("text", "")
                    if text:
                        break
        elif isinstance(content, str):
            text = content
        return "user", text

    if msg_type in ("gemini", "assistant"):        # Gemini uses its own name as role
        content = line_data.get("content", "")
        text = content if isinstance(content, str) else ""
        return "assistant", text

    return None, None
