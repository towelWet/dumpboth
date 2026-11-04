#!/usr/bin/env python3
# lib/parsers/opencode.py — OpenCode JSONL/JSON session parser
# NEVER DELETE COMMENTS — explain every non-obvious line. Update comments with the code.

CLI_TYPE = "opencode"

def parse(line_data):
    """Return (role, text) or (None, None) to skip."""
    role = line_data.get("role", "")
    content = line_data.get("content", "")
    text = ""

    if isinstance(content, str):
        text = content
    elif isinstance(content, list):
        for item in content:
            if isinstance(item, dict):
                t = item.get("text", "")
                if t: text = t; break
            elif isinstance(item, str):
                text = item; break

    if role and text:
        if text.strip().startswith("<system-reminder>"):
            return None, None
        if "<command-message>" in text or "<command-name>" in text:
            return None, None
        return role, text

    # Try nested message format
    msg = line_data.get("message", {})
    if msg:
        role = msg.get("role", "")
        content = msg.get("content", "")
        if isinstance(content, str):
            text = content
        elif isinstance(content, list):
            for item in content:
                if isinstance(item, dict):
                    t = item.get("text", "")
                    if t: text = t; break
    if role and text:
        if text.strip().startswith("<system-reminder>"):
            return None, None
        return role, text
    return None, None
