#!/usr/bin/env python3
# cli.py — the actual `/dumpboth detect` entry point: wires scan_pairs + report_desync.
# WHY IT EXISTS: keeps argv handling out of the two pure functions above so they stay
# reusable (e.g. by a future TUI) without dragging sys.argv parsing along.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.

import sys                                           # argv + exit code
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))       # so sibling imports work run from anywhere
from scan_pairs import scan_pairs                    # noqa: E402  (import-after-sys.path is deliberate)
from report_desync import report_desync              # noqa: E402
from suggest_fix import suggest_fix                  # noqa: E402
from load_known_lost import load_known_lost          # noqa: E402


def main() -> int:                                    # one function per file
    if len(sys.argv) < 2:
        print("usage: cli.py <old_chats_dir>", file=sys.stderr)
        return 2
    old_chats_dir = sys.argv[1]
    root_dir = str(Path(__file__).parent.parent.parent)   # repo root: fixes name render.py and agents/
    pairs = scan_pairs(old_chats_dir)
    lost = load_known_lost(str(Path(__file__).parent.parent.parent / "db"))  # skill's db/
    accepted = {n: lost[n] for n in pairs if n in lost}   # markers that match a scanned number
    for n in accepted:
        pairs.pop(n)                                 # accepted gaps are not desync
    print(report_desync(pairs))
    if accepted:
        print(f"\nKnown lost, accepted ({len(accepted)}) — see db/known-lost/:")
        for n, reason in sorted(accepted.items()):
            print(f"  oldchat{n}: {reason[:90]}")
    fixes = suggest_fix(pairs, old_chats_dir, root_dir)
    if fixes:
        print("\nEasy fixes available (fills the gap without re-hunting a lost source):")
        for line in fixes:
            print(f"\n{line}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
