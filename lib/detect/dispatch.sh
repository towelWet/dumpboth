#!/bin/bash
# dispatch.sh — handle `dumpboth detect [home|target_dir]` early-exit.
# Sourced by orchestrator; exits process if detect mode detected.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

if [[ "${1:-}" == "detect" ]]; then
  shift
  TARGET_DIR="$HOME"
  [[ "${1:-}" == "home" ]] && TARGET_DIR="$HOME"
  [[ -n "${1:-}" && "${1:-}" != "home" ]] && TARGET_DIR="$1"
  python3 "$DUMPBOTH_SCRIPT_DIR/lib/detect/cli.py" "$TARGET_DIR/Old Chats"
  exit $?
fi
