#!/usr/bin/env python3
# extract_user_text.py — real user words from Cursor's wrapped message.
# Why: Cursor wraps queries in <user_query> plus injected tags.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import re

USER_QUERY = re.compile(r"<user_query>\s*(.*?)\s*</user_query>", re.S)
TAG = re.compile(r"<[^>]+>")


def extract_user_text(text):
    found = USER_QUERY.search(text)
    if found:
        return found.group(1).strip()
    return TAG.sub("", text).strip() or text.strip()            # all tags: keep original over empty turn
