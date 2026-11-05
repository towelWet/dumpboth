#!/bin/bash
# dumpchat-devin — Devin CLI session dump dispatcher (readable .md).
# Reads ONE exact session from ~/.local/share/devin/cli/sessions.db and renders it to
# <target>/Old Chats/oldchatN[.suffix].md. Never "most recent" (dumped wrong chats 2026-11-05).
# Args: [home] [-append -suffix|suffix] [id <ID>] [target_dir]
# ID: `id <ID>` arg, else DEVIN_SESSION_ID env; neither → refuse. Real work lives in lib/devin/.
set -uo pipefail

LIB="$(cd "$(dirname "$0")" && pwd)/lib/devin"

APPEND=""
TARGET_DIR="$HOME"                                          # never the shell cwd
while [[ $# -gt 0 ]]; do
  case "$1" in
    home)            TARGET_DIR="$HOME"; shift ;;                 # -> ~/Old Chats/
    -append|append)  shift; APPEND="${1:-}"; APPEND="${APPEND#-}"; shift ;;
    id|-id|--id)     shift; export DEVIN_WANT_ID="${1:-}"; shift ;;  # exact Devin session ID (not a UUID)
    *)               [[ -d "$1" ]] && TARGET_DIR="$1"; shift ;;   # explicit target dir; ignore stray tokens
  esac
done

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/block/refuse_scam_dir.sh"
refuse_scam_old_chats "$TARGET_DIR"
# export writes to $DEVIN_OUTDIR (default ~/Old Chats); point it at the chosen target.
EXPORT_FILE=$(DEVIN_OUTDIR="$TARGET_DIR/Old Chats" "$LIB/export" "$APPEND") || exit 1
echo "Exported Devin session to $EXPORT_FILE"
