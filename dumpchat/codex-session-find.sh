#!/bin/bash
# codex-session-find.sh — print path of current Codex session rollout (.jsonl).
# Why: dumpchat-codex (.md) and dumpjsonl-codex (.jsonl) must pick the SAME session,
#      so both source this one finder instead of each guessing.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

codex_session_file() {
  local root="$HOME/.codex/sessions"
  [[ -d "$root" ]] || return 1
  if [[ -n "${CODEX_THREAD_ID:-}" ]]; then                    # Codex sets this inside a task: exact session
    local hit
    hit=$(find -L "$root" -type f -name "rollout-*${CODEX_THREAD_ID}.jsonl" 2>/dev/null | head -1)
    [[ -n "$hit" ]] && { echo "$hit"; return 0; }
  fi
  # -L: ~/.codex/sessions is often a symlink (moved to external drive); plain find skips it
  find -L "$root" -type f -name "rollout-*.jsonl" -print0 2>/dev/null \
    | xargs -0 stat -f '%m %N' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-   # newest = live task
}
