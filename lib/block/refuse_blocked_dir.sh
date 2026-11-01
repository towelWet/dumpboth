# Optional guard: refuse to write dumps into a directory you never want them in.
# Set DUMPBOTH_BLOCK_DIR to an absolute path to block that folder (and anything under it);
# leave it unset (the default) and this is a no-op. Matches the physical path so a trailing
# slash, symlink, or nested folder cannot walk around the check.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
refuse_blocked_dir() {
  local target="${1:-}"
  local blocked="${DUMPBOTH_BLOCK_DIR:-}"      # empty by default → nothing is blocked
  [ -n "$blocked" ] || return 0                # no guard configured
  local resolved blocked_real
  resolved=$(cd "$target" 2>/dev/null && pwd -P) || resolved="$target"
  blocked_real=$(cd "$blocked" 2>/dev/null && pwd -P) || blocked_real="$blocked"
  case "$resolved" in
    "$blocked_real"|"$blocked_real"/*)
      echo "dumpboth: refused. $blocked_real is blocked (DUMPBOTH_BLOCK_DIR)." >&2
      exit 1
      ;;
  esac
}
