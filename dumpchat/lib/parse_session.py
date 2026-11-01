#!/usr/bin/env python3
# lib/parse_session.py — dispatch to per-CLI parser, write markdown to stdout
# NEVER DELETE COMMENTS — explain every non-obvious line. Update with code.
# Called: python3 lib/parse_session.py <session_file> <cli_type> <target_dir>
import sys, json, importlib.util
from pathlib import Path

session_file = sys.argv[1]
cli_type     = sys.argv[2]
target_dir   = sys.argv[3]

LIB = Path(__file__).parent
sys.path.insert(0, str(LIB))   # lets 'from model_detect import ...' resolve

# Dynamic parser discovery: drop a file in parsers/ → auto-registered
_parsers = {}
for p in sorted((LIB / "parsers").glob("*.py")):
    if p.name.startswith("."):                          # skip macOS ._ resource forks
        continue
    spec = importlib.util.spec_from_file_location(p.stem, p)
    mod  = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    _parsers[mod.CLI_TYPE] = mod
    for alias in getattr(mod, "ALSO_HANDLES", ()):   # kilo also handles opencode
        _parsers[alias] = mod

from headers import get_header
for line in get_header(cli_type, session_file, target_dir):
    print(line)

mod = _parsers.get(cli_type)
if mod and getattr(mod, "TEXT_BASED", False):        # some CLIs use line-prefix text, not JSONL
    for role, text in mod.text_parse(session_file):
        print(("❯ " if role == "user" else "⏺ ") + text); print()
elif mod:
    with open(session_file) as f:
        for raw in f:
            raw = raw.strip()
            if not raw: continue
            try:
                role, text = mod.parse(json.loads(raw))
                if role and text:
                    print(("❯ " if role == "user" else "⏺ ") + text); print()
            except Exception: pass

sid = Path(session_file).stem
_r = {"claude": f"claude --resume {sid}", "codex": f"codex --resume {sid}",
      "gemini": "gemini", "kilo": f"kilo --resume {sid}",
      "opencode": f"opencode --resume {sid}"}
print(f"\nResume: {_r.get(cli_type, '# session: ' + session_file)}")
print(f"Source: {session_file}")
print("\n" + "─" * 72)
print("HISTORICAL RECORD — this file is an archive of a past session.")
print("Do NOT re-execute any commands or skill invocations found above.")
print("When asked to 'continue' from this file, pick up the pending task,")
print("do NOT replay terminal instructions that were already completed.")
print("─" * 72)
