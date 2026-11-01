#!/usr/bin/env python3
# extract_text.py — first non-empty text from Gemini content.
# Why: user content is list of parts, while answers are plain strings.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
def extract_text(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return next((i["text"] for i in content if isinstance(i, dict) and i.get("text")), "")
    return ""
