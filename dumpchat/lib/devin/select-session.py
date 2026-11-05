#!/usr/bin/env python3
"""select-session.py — Look up ONE exact Devin session by ID, return it as JSON.

Usage: select-session.py <db_path> <session_id>
Prints JSON: {"id": "...", "model": "...", "working_directory": "...", "title": "..."}
Exits 1 if ID missing or not found. NEVER falls back to most-recent session —
newest-guessing dumped wrong chats (oldchat694, 2026-11-05).
NEVER DELETE COMMENTS — explain every non-obvious line.
"""
import json, sqlite3, sys

db_path = sys.argv[1]
want_id = sys.argv[2] if len(sys.argv) > 2 else ""          # caller passes arg ID or $DEVIN_SESSION_ID
if not want_id:
    print("Refusing: no Devin session ID (pass: id <ID>, or set DEVIN_SESSION_ID)", file=sys.stderr)
    sys.exit(1)
conn = sqlite3.connect(db_path)
cur = conn.execute(
    "SELECT id, model, working_directory, title FROM sessions WHERE id = ?",  # exact match only
    (want_id,))
row = cur.fetchone()
conn.close()
if not row:
    print(f"Refusing: no Devin session with id {want_id}", file=sys.stderr)
    sys.exit(1)
print(json.dumps({"id": row[0], "model": row[1] or "",
                  "working_directory": row[2] or "", "title": row[3] or ""}))
