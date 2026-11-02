#!/usr/bin/env python3
"""normalize-messages.py — Strip Devin noise, deduplicate, emit clean JSONL."""
import json, re, sys

DEVIN_NOISE = re.compile(r'^(?:Thought for \d+s|Analyzed[~\s][^\n]*|Searched\*[^\n]*|Read[^\n]+files?|Feedback submitted|Summary of \d+[^\n]*|Ran \d+[^\n]*|Opened \d+[^\n]*|Wrote \d+[^\n]*|Created \d+[^\n]*|Edited \d+[^\n]*|Deleted \d+[^\n]*|Found \d+[^\n]*|Viewed \d+[^\n]*|Skipped \d+[^\n]*|Copied \d+[^\n]*|Moved \d+[^\n]*|Resolved \d+[^\n]*|Downloaded \d+[^\n]*|Uploaded \d+[^\n]*)\s*$', re.MULTILINE)
USER_PREAMBLE = re.compile(r"^\s*(\d+\s*m\s*\n)+'[^']*'\s*\n\n?")

def is_system_blob(text):
    return text.startswith('<project_context') or text.startswith('<session_context')

def clean(text):
    text = USER_PREAMBLE.sub('', text)
    text = DEVIN_NOISE.sub('', text)
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()

last_role = last_text = None
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    msg = json.loads(line)
    role, text = msg.get("role"), msg.get("text", "")
    if not text or is_system_blob(text): continue
    text = clean(text)
    if not text: continue
    if role == last_role and text == last_text: continue
    print(json.dumps({"role": role, "text": text}, ensure_ascii=False))
    last_role, last_text = role, text
