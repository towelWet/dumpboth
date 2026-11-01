#!/usr/bin/env python3
# clean_text.py — strip Devin UI noise and preamble from one message.
# Why: dumps should read as conversation, not status lines.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import re

DEVIN_NOISE = re.compile(r'^(?:Thought for \d+s|Analyzed[~\s][^\n]*|Searched\*[^\n]*|Read[^\n]+files?|Feedback submitted|Summary of \d+[^\n]*|Ran \d+[^\n]*|Opened \d+[^\n]*|Wrote \d+[^\n]*|Created \d+[^\n]*|Edited \d+[^\n]*|Deleted \d+[^\n]*|Found \d+[^\n]*|Viewed \d+[^\n]*|Skipped \d+[^\n]*|Copied \d+[^\n]*|Moved \d+[^\n]*|Resolved \d+[^\n]*|Downloaded \d+[^\n]*|Uploaded \d+[^\n]*)\s*$', re.MULTILINE)
USER_PREAMBLE = re.compile(r"^\s*(\d+\s*m\s*\n)+'[^']*'\s*\n\n?")


def clean_text(text):
    text = USER_PREAMBLE.sub('', text)
    text = DEVIN_NOISE.sub('', text)
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()
