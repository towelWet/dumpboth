#!/bin/bash
# session.sh — print current Codex rollout file: named id, running task, else newest.
# Why: CODEX_THREAD_ID is exact inside Codex task; find -L because sessions is often a symlink.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
ROOT="$HOME/.codex/sessions"
[[ -d "$ROOT" ]] || exit 1
WANT="${1:-${CODEX_THREAD_ID:-}}"
if [[ -n "$WANT" ]]; then
  HIT="$(find -L "$ROOT" -type f -name "rollout-*$WANT.jsonl" 2>/dev/null | head -1)"
  [[ -n "$HIT" ]] && { echo "$HIT"; exit 0; }
fi
find -L "$ROOT" -type f -name 'rollout-*.jsonl' -print0 2>/dev/null \
  | xargs -0 stat -f '%m %N' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-
