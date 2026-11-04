#!/bin/bash
# realpath.sh — portable realpath via python3 (macOS lacks GNU realpath).
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

dumpchat_realpath() {
  python3 -c 'import os,sys; print(os.path.realpath(os.path.expanduser(sys.argv[1])))' "$1" 2>/dev/null || echo "$1"
}
