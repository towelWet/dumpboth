#!/bin/bash
# dumpchat-devin — Devin CLI session dump dispatcher (readable .md).
# Reads the live session from ~/.local/share/devin/cli/sessions.db (most recent by
# last_activity_at) and renders it to <target>/Old Chats/oldchatN[.suffix].md.
# Args: [home] [-append -suffix|suffix] [target_dir]   (uuid args are ignored —
# Devin selects the current session automatically). Real work lives in lib/devin/.
set -uo pipefail

LIB="$(cd "$(dirname "$0")" && pwd)/lib/devin"

APPEND=""
TARGET_DIR="$HOME"                                          # never the shell cwd
while [[ $# -gt 0 ]]; do
  case "$1" in
    home)            TARGET_DIR="$HOME"; shift ;;                 # -> ~/Old Chats/
    -append|append)  shift; APPEND="${1:-}"; APPEND="${APPEND#-}"; shift ;;
    *)               [[ -d "$1" ]] && TARGET_DIR="$1"; shift ;;   # explicit target dir; ignore stray tokens
  esac
done

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../dumpboth/lib/block/refuse_scam_dir.sh"
refuse_scam_old_chats "$TARGET_DIR"
# export writes to $DEVIN_OUTDIR (default ~/Old Chats); point it at the chosen target.
EXPORT_FILE=$(DEVIN_OUTDIR="$TARGET_DIR/Old Chats" "$LIB/export" "$APPEND") || exit 1
echo "Exported Devin session to $EXPORT_FILE"
