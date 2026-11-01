#!/usr/bin/env python3
"""select-session.py — Query sessions table, return most recent session with messages as JSON.

Usage: select-session.py <db_path>
Prints JSON: {"id": "...", "model": "...", "working_directory": "...", "title": "..."}
Exits 1 if no session found.
"""
import json, sqlite3, sys

db_path = sys.argv[1]
conn = sqlite3.connect(db_path)
cur = conn.execute("""
    SELECT s.id, s.model, s.working_directory, s.title
    FROM sessions s
    LEFT JOIN message_nodes m ON s.id = m.session_id
        AND json_extract(m.chat_message, '$.role') IN ('user', 'assistant')
    GROUP BY s.id
    HAVING COUNT(m.row_id) > 0
    ORDER BY s.last_activity_at DESC
    LIMIT 1
""")
row = cur.fetchone()
conn.close()
if not row:
    print(json.dumps({"error": "No sessions with messages found"}), file=sys.stderr)
    sys.exit(1)
print(json.dumps({"id": row[0], "model": row[1] or "",
                  "working_directory": row[2] or "", "title": row[3] or ""}))
