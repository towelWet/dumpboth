#!/usr/bin/env python3
# lib/parsers/god.py — God CLI text-based session parser
# NEVER DELETE COMMENTS — explain every non-obvious line. Update comments with the code.
# God sessions are plain text with marker prefixes, not JSONL.

CLI_TYPE = "god"
TEXT_BASED = True   # signals parse_session.py to call text_parse() instead of parse()

def parse(line_data):
    """Not used — God sessions are not JSONL. TEXT_BASED flag routes to text_parse()."""
    return None, None

def text_parse(session_file):
    """Yield (role, text) from God's [USER]/[ASSISTANT] line-prefix format."""
    with open(session_file) as f:
        for line in f:
            line = line.rstrip('\n')
            if line.startswith("[USER]"):
                yield "user", line[6:].strip()
            elif line.startswith("[ASSISTANT]"):
                yield "assistant", line[11:].strip()
            # [THINKING] lines are silently dropped
