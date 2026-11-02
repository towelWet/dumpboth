#!/bin/bash
# Shared session discovery for dumpchat — find/jsonl when allowed, Finder/osascript when EPERM.

dumpchat_realpath() {
  python3 -c 'import os,sys; print(os.path.realpath(os.path.expanduser(sys.argv[1])))' "$1" 2>/dev/null || echo "$1"
}

# Find one session file under root whose basename matches SESSION_ID*.jsonl
dumpchat_finder_find_by_id() {
  local root="$1"
  local sid="$2"
  [ -n "$root" ] && [ -n "$sid" ] || return 1
  osascript - "$root" "$sid" <<'APPLESCRIPT' 2>/dev/null
on run argv
  set rootPOSIX to item 1 of argv
  set sid to item 2 of argv
  tell application "Finder"
    set rootFolder to folder (POSIX file rootPOSIX as alias)
    repeat with projFolder in every folder of rootFolder
      try
        set targetFile to (first item of projFolder whose name starts with sid and name ends with ".jsonl")
        return POSIX path of (targetFile as alias)
      end try
    end repeat
  end repeat
  return ""
end run
APPLESCRIPT
}

# List "mtime path" lines for jsonl under claude projects (shell or Finder).
dumpchat_claude_jsonl_candidates() {
  local root
  root="$(dumpchat_realpath "$HOME/.claude/projects")"
  [ -d "$root" ] || return 0

  local -a shell_lines=()
  while IFS= read -r -d '' file; do
    local mtime
    mtime=$(stat -f '%m' "$file" 2>/dev/null) || continue
    shell_lines+=("$mtime $file")
  done < <(find "$root" -type f -name "*.jsonl" -print0 2>/dev/null)

  if [ "${#shell_lines[@]}" -gt 0 ]; then
    printf '%s\n' "${shell_lines[@]}"
    return 0
  fi

  # Finder fallback when find is EPERM-blocked (external .claude tree).
  local paths p mtime
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    mtime=$(stat -f '%m' "$p" 2>/dev/null) || continue
    echo "$mtime $p"
  done < <(osascript - "$root" <<'APPLESCRIPT' 2>/dev/null
on run argv
  set rootPOSIX to item 1 of argv
  set out to ""
  tell application "Finder"
    set rootFolder to folder (POSIX file rootPOSIX as alias)
    repeat with projFolder in every folder of rootFolder
      repeat with f in (every document file of projFolder whose name ends with ".jsonl")
        set out to out & (POSIX path of (f as alias)) & linefeed
      end repeat
    end repeat
  end repeat
  return out
end tell
APPLESCRIPT
)
}

# Resolve session file: optional UUID, else CLAUDE_CODE_SESSION_ID, else newest non-memory.
dumpchat_resolve_session_file() {
  local want_id="${1:-}"
  local dir file found

  if [ -n "$want_id" ]; then
    for dir in \
      "$(dumpchat_realpath "$HOME/.claude/projects")" \
      "$HOME/.codex/sessions" \
      "$HOME/.gemini/tmp" \
      "$HOME/.kilocode/storage/session" \
      "$HOME/.kilo/storage/session" \
      "$HOME/.opencode" \
      "$HOME/.god/sessions"; do
      [ -d "$dir" ] || continue
      found=$(find "$dir" -type f -name "${want_id}*.jsonl" 2>/dev/null | head -1)
      if [ -n "$found" ] && [ -f "$found" ]; then
        echo "$found"
        return 0
      fi
      if [[ "$dir" == *".claude/projects"* ]]; then
        found=$(dumpchat_finder_find_by_id "$dir" "$want_id")
        if [ -n "$found" ] && [ -r "$found" ]; then
          echo "$found"
          return 0
        fi
      fi
    done
    return 1
  fi

  if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
    dumpchat_resolve_session_file "$CLAUDE_CODE_SESSION_ID" && return 0
  fi

  local candidates line candidate

  # Always try Claude sessions first — never mix with other CLIs unless Claude has nothing.
  candidates="$(dumpchat_claude_jsonl_candidates)"
  local claude_found=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    candidate="${line#* }"
    [ -z "$candidate" ] || [ ! -r "$candidate" ] && continue
    if grep -q "Hello memory agent" "$candidate" 2>/dev/null; then
      continue
    fi
    claude_found="$candidate"
    break
  done < <(printf '%s\n' "$candidates" | sort -rn)

  if [ -n "$claude_found" ]; then
    echo "$claude_found"
    return 0
  fi

  # Fallback: scan other CLI dirs only if no Claude session found.
  candidates=""
  for dir in "$HOME/.codex/sessions" "$HOME/.gemini/tmp" "$HOME/.kilocode/storage/session" \
    "$HOME/.kilo/storage/session" "$HOME/.opencode" "$HOME/.god/sessions"; do
    [ -d "$dir" ] || continue
    while IFS= read -r -d '' file; do
      local mtime
      mtime=$(stat -f '%m' "$file" 2>/dev/null) || continue
      candidates+=$'\n'"$mtime $file"
    done < <(find "$dir" -type f \( -name "*.jsonl" -o -name "*.json" -o -name "*.txt" \) -print0 2>/dev/null)
  done

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    candidate="${line#* }"
    [ -z "$candidate" ] || [ ! -r "$candidate" ] && continue
    if grep -q "Hello memory agent" "$candidate" 2>/dev/null; then
      continue
    fi
    echo "$candidate"
    return 0
  done < <(printf '%s\n' "$candidates" | sort -rn)

  return 1
}
