#!/usr/bin/env python3
# render.py — print one session as readable markdown: header, turns, resume, source.
# Why: same output shape for each agent; agent.toml + turn.py hold what differs.
# Usage: render.py <agent_dir> <session_file> <target_dir>
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import re, sys
from pathlib import Path
from load_agent import load_agent
from read_turns import read_turns
from merge_turns import merge_turns

UUID = re.compile(r"[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}")   # some agents wrap id: rollout-<date>-<uuid>
MARK = {"user": "\u276f", "assistant": "\u23fa"}               # same marks in every agent's dump


def render(agent_dir, session_file, target_dir):
    agent = load_agent(agent_dir)
    fields = {"target": target_dir, "source": session_file, "sid": (lambda stem: (UUID.search(stem) or [stem])[0])(Path(session_file).stem),
              "model": agent["model"](session_file)}
    for line in agent["header"]:
        print(line.format(**fields))
    print()
    for role, text in merge_turns(read_turns(session_file, agent["turn"]), agent.get("join"), agent.get("dedupe")):
        print(f"{MARK[role]} {text}\n")
    print(f"\nResume: {agent['resume'].format(**fields)}\nSource: {session_file}")
    for line in agent.get("footer", []):
        print(line)


if __name__ == "__main__":
    render(*sys.argv[1:4])
