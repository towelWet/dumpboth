#!/bin/bash
# dumpchat-session-find.sh — backward-compat shim: sources split session lib.
# All real logic lives in lib/session/ (one function per file).
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

_DUMPCHAT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_DUMPCHAT_DIR/lib/session/resolve.sh"
