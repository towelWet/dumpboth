#!/usr/bin/env python3
# opencode-render-md.py — readable .md from OpenCode .jsonl (argv[1]), printed to stdout.
# Why: gives /dumpboth opencode same ❯ / ⏺ transcript shape as every other agent's dump.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import json, sys


def render(path):
    lines = open(path, encoding="utf-8").read().splitlines()
    head = json.loads(lines[0])["info"]                                # first line = session header
    print(f"  OpenCode\n  {head.get('directory', '')}\n")
    for line in lines[1:]:
        message = json.loads(line)
        mark = "❯" if message["info"].get("role") == "user" else "⏺"
        for part in message.get("parts", []):
            if part.get("type") == "text" and not part.get("synthetic") and part.get("text", "").strip():
                print(f"{mark} {part['text'].strip()}\n")
            elif part.get("type") == "tool":                           # name + input + output, as other dumps show
                state = part.get("state", {})
                print(f"⏺ {part.get('tool')}({json.dumps(state.get('input', {}), ensure_ascii=False)})")
                print(f"  ⎿ {state.get('output') or state.get('error') or ''}\n")
    print(f"Resume: opencode --session {head.get('id', '')}")


if __name__ == "__main__":
    render(sys.argv[1])
