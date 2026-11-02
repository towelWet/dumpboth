#!/bin/bash
set -uo pipefail

# dumpchat-kilo.command — dump the most recent Kilo (Kilocode) session
# Usage:
#   dumpchat-kilo.command                          → Old Chats/oldchatN.md
#   dumpchat-kilo.command -append -suffix          → Old Chats/oldchatN-suffix.md
#   dumpchat-kilo.command /path/to/dir               → /path/to/dir/Old Chats/oldchatN.md
#   dumpchat-kilo.command /path/to/dir -append -sfx  → /path/to/dir/Old Chats/oldchatN-sfx.md

APPEND_SUFFIX=""
TARGET_DIR="$HOME"                                          # never the shell cwd

while [[ $# -gt 0 ]]; do
  case "$1" in
    -append)
      shift
      APPEND_SUFFIX="${1:-}"
      APPEND_SUFFIX="${APPEND_SUFFIX#-}"
      shift
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/block/refuse_scam_dir.sh"
refuse_scam_old_chats "$TARGET_DIR"
OLD_CHATS_DIR="$TARGET_DIR/Old Chats"
mkdir -p "$OLD_CHATS_DIR"

python3 << 'PYTHON_EOF'
import json, os, sys, glob

home = os.path.expanduser("~")
target_dir = os.environ.get("TARGET_DIR", os.getcwd())
append_suffix = os.environ.get("APPEND_SUFFIX", "")

# Kilo session storage locations
session_roots = [
    os.path.join(home, ".kilocode", "storage", "session", "message"),
    os.path.join(home, ".kilo", "storage", "session", "message"),
]

# Find the most recently modified message JSON across all session dirs
newest_mtime = 0
newest_file = None
newest_session_dir = None

for root in session_roots:
    if not os.path.isdir(root):
        continue
    for session_dir in os.listdir(root):
        sd = os.path.join(root, session_dir)
        if not os.path.isdir(sd):
            continue
        for fname in os.listdir(sd):
            fpath = os.path.join(sd, fname)
            if not os.path.isfile(fpath) or not fname.endswith(".json"):
                continue
            try:
                mtime = os.path.getmtime(fpath)
            except OSError:
                continue
            if mtime > newest_mtime:
                newest_mtime = mtime
                newest_file = fpath
                newest_session_dir = sd

if newest_session_dir is None:
    print("No Kilo sessions found in ~/.kilocode/ or ~/.kilo/")
    sys.exit(0)

session_id = os.path.basename(newest_session_dir)

# Collect all message files in that session, sorted by name (which is typically a timestamp or sequence number)
msg_files = sorted(
    [os.path.join(newest_session_dir, f) for f in os.listdir(newest_session_dir)
     if f.endswith(".json") and os.path.isfile(os.path.join(newest_session_dir, f))]
)

# Parse each message
messages = []
for fp in msg_files:
    try:
        with open(fp, "r") as f:
            data = json.load(f)
    except (json.JSONDecodeError, IOError):
        continue

    role = data.get("role", "") if isinstance(data, dict) else ""
    if role not in ("user", "assistant"):
        continue

    content = data.get("content", "")
    text = ""
    if isinstance(content, str):
        text = content
    elif isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict) and "text" in item:
                parts.append(item["text"])
        text = "\n".join(parts)

    if text:
        messages.append((role, text))

# Determine output filename with auto-increment
old_chats_dir = os.path.join(target_dir, "Old Chats")
os.makedirs(old_chats_dir, exist_ok=True)

next_num = 0
for fname in os.listdir(old_chats_dir):
    if fname.startswith("oldchat") and fname.endswith(".md"):
        try:
            num_part = fname[len("oldchat"):]
            if "-" in num_part:
                num_part = num_part.split("-")[0]
            n = int(num_part)
            if n >= next_num:
                next_num = n
        except ValueError:
            pass
next_num += 1

if append_suffix:
    export_path = os.path.join(old_chats_dir, f"oldchat{next_num}-{append_suffix}.md")
else:
    export_path = os.path.join(old_chats_dir, f"oldchat{next_num}.md")

# Write Markdown output
with open(export_path, "w") as out:
    out.write(" ╔════╗   Kilo Code\n")
    out.write("║ ☰ ║  Kilocode · Multi-Provider\n")
    out.write("  ▘▘ ▝▝    %s\n" % target_dir)
    out.write("\n")

    for role, text in messages:
        if role == "user":
            out.write("❯ " + text + "\n\n")
        elif role == "assistant":
            out.write("⏺ " + text + "\n\n")

    out.write("\n")
    out.write("Resume: kilo --resume %s\n" % session_id)
    out.write("Detected: KILO | Session: %s | Source: %s\n" % (session_id, newest_session_dir))

print("Exported session to %s (kilo)" % export_path)
PYTHON_EOF
