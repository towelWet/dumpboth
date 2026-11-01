#!/usr/bin/env python3
# opencode-export.py — write newest non-empty OpenCode session as .jsonl (argv[1]).
# Why: current OpenCode keeps sessions in SQLite; official `opencode export` is its stable
#      way out. It emits one JSON document, so split it: header line, then one line per message.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import json, os, subprocess, sys, tempfile


def opencode_export(out):
    listed = subprocess.run(["opencode", "session", "list", "--format", "json", "-n", "50"],
                            capture_output=True, text=True).stdout     # scoped to current project, newest first
    sessions = json.loads(listed[listed.find("["):]) if "[" in listed else []
    if os.environ.get("OPENCODE_SESSION_ID"):
        sessions = [{"id": os.environ["OPENCODE_SESSION_ID"]}]         # caller named exact session
    for session in sessions:
        if "updated" in session and session["updated"] == session.get("created"):
            continue                                                   # never touched = no messages; skips slow export
        with tempfile.TemporaryFile(mode="w+", encoding="utf-8") as spool:   # auto-removed on close
            subprocess.run(["opencode", "export", session["id"]], stdout=spool, stderr=subprocess.DEVNULL)
            spool.seek(0)                                              # file, not pipe: export truncates pipes near 72 KB
            raw = spool.read()
        doc = json.loads(raw[raw.find("{"):])                          # tolerate any banner before JSON
        if not doc.get("messages"):
            continue
        with open(out, "w", encoding="utf-8") as f:
            f.write(json.dumps({"info": doc["info"]}, ensure_ascii=False) + "\n")   # session header
            for message in doc["messages"]:
                f.write(json.dumps(message, ensure_ascii=False) + "\n")   # {info, parts}
        print(session["id"], file=sys.stderr)                          # stderr: out may be /dev/stdout
        return 0
    print("No OpenCode session with messages found.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(opencode_export(sys.argv[1]))
