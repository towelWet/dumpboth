#!/usr/bin/env python3
# report_desync.py — turn scan_pairs()'s dict into a human-readable desync report.
# WHY IT EXISTS: the rendering half, split from scan_pairs.py (one
# function per file) — this ONLY formats, it never touches the filesystem.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.


def report_desync(pairs: dict) -> str:                # one function per file
    orphan_md_only = []                                # number has .md but no .jsonl
    orphan_jsonl_only = []                             # number has .jsonl but no .md
    tag_mismatch = []                                  # both exist, both tagged, tags differ

    for num in sorted(pairs):
        slot = pairs[num]
        has_md, has_jsonl = slot["md"] is not None, slot["jsonl"] is not None
        if has_md and not has_jsonl:
            orphan_md_only.append(num)
        elif has_jsonl and not has_md:
            orphan_jsonl_only.append(num)
        elif has_md and has_jsonl:
            if slot["md_tag"] and slot["jsonl_tag"] and slot["md_tag"] != slot["jsonl_tag"]:
                tag_mismatch.append(num)

    lines = []
    total = len(pairs)
    complete = total - len(orphan_md_only) - len(orphan_jsonl_only)
    lines.append(f"dumpboth desync report — {total} number(s) scanned, {complete} complete pair(s)")

    if orphan_md_only:
        lines.append(f"\nMD only, no matching .jsonl ({len(orphan_md_only)}):")
        lines.extend(f"  oldchat{n}.md" for n in orphan_md_only)

    if orphan_jsonl_only:
        lines.append(f"\nJSONL only, no matching .md ({len(orphan_jsonl_only)}):")
        lines.extend(f"  oldchat{n}.jsonl" for n in orphan_jsonl_only)

    if tag_mismatch:
        lines.append(f"\nSAME NUMBER, MISMATCHED TAGS — likely two unrelated dumps sharing a number ({len(tag_mismatch)}):")
        for n in tag_mismatch:
            slot = pairs[n]
            lines.append(f"  oldchat{n}: md tag={slot['md_tag']}  jsonl tag={slot['jsonl_tag']}")

    if not orphan_md_only and not orphan_jsonl_only and not tag_mismatch:
        lines.append("\nNo desync detected — every number has a matching md+jsonl pair.")

    return "\n".join(lines)
