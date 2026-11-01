#!/usr/bin/env python3
# run_tests.py — run dumpboth for each case in cases.toml inside throwaway HOME.
# Why: proves numbering, pairing, filtering, and raw copy on synthetic chats; real chats stay untouched.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import os, subprocess, tempfile, tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOST_IDS = ("CLAUDE_CODE_SESSION_ID", "CODEX_THREAD_ID", "OPENCODE_SESSION_ID", "DUMPBOTH_BLOCK_DIR")   # would point at real chat


def run_tests():
    failures = 0
    for case in tomllib.loads((ROOT / "tests/cases.toml").read_text(encoding="utf-8"))["case"]:
        home = Path(tempfile.mkdtemp(prefix="dumpboth-test-"))        # outside any real chat folder
        fixture = (ROOT / "tests/fixtures" / case["fixture"]).read_bytes()
        session = home / case["session"]
        session.parent.mkdir(parents=True)
        session.write_bytes(fixture)
        env = {k: v for k, v in os.environ.items() if k not in HOST_IDS} | {"HOME": str(home)}
        for _ in range(2):                                            # second run must take next number
            subprocess.run([ROOT / "dumpboth.command", case["agent"], "demo"], env=env, capture_output=True)
        out = home / "Old Chats"
        md = sorted(out.glob("oldchat1-demo-*.md"))
        jsonl = sorted(out.glob("oldchat1-demo-*.jsonl"))
        text = md[0].read_text(encoding="utf-8") if md else ""
        problems = [f"missing: {e!r}" for e in case["expect"] if e not in text]
        problems += [f"leaked: {r!r}" for r in case["reject"] if r in text]
        if not jsonl or jsonl[0].read_bytes() != fixture:
            problems.append("jsonl is not exact copy")
        if not md or not jsonl or md[0].stem != jsonl[0].stem:
            problems.append("pair names differ")
        if len(list(out.glob("oldchat2-demo-*"))) != 2:
            problems.append("second run did not take next number")
        print(("FAIL " if problems else "PASS ") + case["agent"], *problems, sep="\n  " if problems else " ")
        failures += bool(problems)
    print(f"{failures} failed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(run_tests())
