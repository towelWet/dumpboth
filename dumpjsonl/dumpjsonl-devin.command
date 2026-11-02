#!/bin/bash
# dumpjsonl-devin — Devin CLI session RAW jsonl dispatcher (verbatim message_nodes).
# Pairs with dumpchat-devin: same session (most recent in the Devin CLI sessions.db),
# same numbering, but emits the untouched chat_message nodes (all roles) one per line
# instead of a rendered transcript. Real work lives in ../dumpchat/lib/devin/export-jsonl.
# Args: [home] [-append -suffix|suffix] [target_dir]
set -uo pipefail

LIB="$(cd "$(dirname "$0")/../dumpchat/lib/devin" && pwd)"

APPEND=""
TARGET_DIR="$HOME"                                          # never the shell cwd
while [[ $# -gt 0 ]]; do
  case "$1" in
    home)            TARGET_DIR="$HOME"; shift ;;
    -append|append)  shift; APPEND="${1:-}"; APPEND="${APPEND#-}"; shift ;;
    *)               [[ -d "$1" ]] && TARGET_DIR="$1"; shift ;;
  esac
done

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/block/refuse_scam_dir.sh"
refuse_scam_old_chats "$TARGET_DIR"
EXPORT_FILE=$(DEVIN_OUTDIR="$TARGET_DIR/Old Chats" "$LIB/export-jsonl" "$APPEND") || exit 1
echo "Exported raw Devin jsonl to $EXPORT_FILE"
