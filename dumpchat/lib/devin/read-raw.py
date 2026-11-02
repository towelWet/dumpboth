#!/usr/bin/env python3
"""read-raw.py — Emit a Devin CLI session's message_nodes VERBATIM as jsonl.

Usage: read-raw.py <db_path> <session_id>
One line per node = the stored `chat_message` JSON, untouched, in node order.
This is the raw/training artifact analog of dumpjsonl (no cleaning, all roles:
system/user/assistant/tool). Only guarantees it's one valid JSON object per line.
"""
import sqlite3, sys

db_path, session_id = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db_path)
cur = conn.execute(
    "SELECT chat_message FROM message_nodes WHERE session_id = ? ORDER BY node_id",
    (session_id,),
)
for (chat_message,) in cur.fetchall():
    if not chat_message:
        continue
    # chat_message is already single-line serialized JSON (real newlines in content
    # are escaped as \n by JSON), so emit it verbatim — one node = one jsonl line.
    print(chat_message)
conn.close()
