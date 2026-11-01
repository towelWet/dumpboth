#!/usr/bin/env python3
"""read-messages.py — Read message_nodes for a session, emit raw JSONL to stdout.

Usage: read-messages.py <db_path> <session_id>
Each output line: {"role": "user"|"assistant", "text": "..."}
Skips empty/system messages.
"""
import json, sqlite3, sys

db_path, session_id = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db_path)
cur = conn.execute("""
    SELECT json_extract(chat_message, '$.role'),
           json_extract(chat_message, '$.content')
    FROM message_nodes
    WHERE session_id = ?
      AND json_extract(chat_message, '$.role') IN ('user', 'assistant')
    ORDER BY node_id
""", (session_id,))
for role, content in cur.fetchall():
    if content:
        text = content.strip()
        if text:
            print(json.dumps({"role": role, "text": text}))
conn.close()
