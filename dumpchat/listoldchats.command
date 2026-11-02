#!/bin/bash
set -euo pipefail

echo "==============================================="
echo "listoldchats.command — old chats dumper"
echo "Started: $(date)"
echo "==============================================="

TARGET_DIR="${1:-.}"
OUT_FILE="$TARGET_DIR/listoldchats.txt"

echo "Target dir: $TARGET_DIR"
echo "Output:     $OUT_FILE"
echo

TMP_LIST="$(mktemp -t listoldchats.XXXXXX)"
trap 'rm -f "$TMP_LIST"' EXIT

find "$TARGET_DIR" -maxdepth 1 -type f -name "*.md" | LC_ALL=C sort > "$TMP_LIST"

total="$(wc -l < "$TMP_LIST" | tr -d ' ')"
echo "Matched files: $total"
echo

{
  echo "==============================================="
  echo "listoldchats.txt — old chat listing + contents"
  echo "Generated: $(date)"
  echo "Directory: $TARGET_DIR"
  echo "==============================================="
  echo

  i=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    i=$((i + 1))
    filename="$(basename "$f")"

    echo "[$i/$total] $filename" >&2

    echo "-----------------------------------------------"
    echo "FILE $i: $filename"
    echo "ABS: $f"
    echo "SIZE: $(/usr/bin/stat -f%z "$f" 2>/dev/null || echo "?") bytes"
    echo "MTIME: $(/usr/bin/stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$f" 2>/dev/null || echo "?")"
    echo "-----------------------------------------------"
    echo

    /bin/cat "$f"
    echo
    echo
  done < "$TMP_LIST"

  echo "==============================================="
  echo "DONE — files dumped: $i"
  echo "Finished: $(date)"
  echo "==============================================="
} > "$OUT_FILE"

echo "Wrote: $OUT_FILE"
echo "Done."
