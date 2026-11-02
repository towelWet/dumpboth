#!/usr/bin/env python3
"""render-markdown.py — Render Devin session as markdown.

Usage: echo '{"role":"user","text":"..."}' | render-markdown.py --model M --title T --dir D

Args: --model <model>  --title <title>  --dir <working directory>
Reads cleaned JSONL from stdin. Writes markdown to stdout.
"""
import json, sys

# Parse named args
model = ""
title = ""
target_dir = ""
args = iter(sys.argv[1:])
for a in args:
    if a == "--model":
        model = next(args, "")
    elif a == "--title":
        title = next(args, "")
    elif a == "--dir":
        target_dir = next(args, "")

# Header
print(" ◐◑●◎◉   Devin CLI")
if model:
    print("  " + model)
if title:
    print("  “" + title + "”")
print("  ▘▘ ▝▝    " + target_dir)
print("")

# Messages
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        msg = json.loads(line)
        role = msg["role"]
        text = msg["text"]
        prefix = "❯ " if role == "user" else "⏺ "
        print(prefix + text)
        print("")
    except (json.JSONDecodeError, KeyError):
        pass
