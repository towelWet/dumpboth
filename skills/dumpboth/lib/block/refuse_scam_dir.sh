# Refuse the project tree that received oldchat1–3.
# That folder is not ~/Old Chats. Real dumps use `dumpboth cursor home`.
# Match the physical path so a trailing slash, symlink, or nested Old Chats
# cannot walk around the exact-string check (2026-10-23).
refuse_scam_old_chats() {
  local target="${1:-}"
  local list                                                 # optional private blocked folder, kept in db/ so it never ships
  list="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/db/blocked-dir"
  local scam=""
  [[ -f "$list" ]] && scam="$(head -n 1 "$list")"
  [[ -z "$scam" ]] && return 0                               # nothing blocked on fresh install
  local resolved scam_real
  resolved=$(cd "$target" 2>/dev/null && pwd -P) || resolved="$target"
  scam_real=$(cd "$scam" 2>/dev/null && pwd -P) || scam_real="$scam"
  case "$resolved" in
    "$scam_real"|"$scam_real"/*)
      echo "dumpboth: refused. $scam_real is blocked. Use: dumpboth cursor home" >&2
      exit 1
      ;;
  esac
}
