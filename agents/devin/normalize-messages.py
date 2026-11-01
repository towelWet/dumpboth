#!/usr/bin/env python3
# normalize-messages.py — strip Devin noise, drop repeats, emit clean JSONL.
# Why: middle step of md.sh pipeline: stdin to stdout, one message per line.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import json, sys
from clean_text import clean_text
from is_system_blob import is_system_blob

last_role = last_text = None
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    msg = json.loads(line)
    role, text = msg.get("role"), msg.get("text", "")
    if not text or is_system_blob(text): continue
    text = clean_text(text)
    if not text: continue
    if role == last_role and text == last_text: continue
    print(json.dumps({"role": role, "text": text}, ensure_ascii=False))
    last_role, last_text = role, text
