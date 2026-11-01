#!/usr/bin/env python3
# load_agent.py — load one agent's data and functions from its folder.
# Why: hot-loadable: new folder under agents/ is new agent, with no edit to core.
# NEVER DELETE COMMENTS — explain every non-obvious line.
# Update comments with the code; do not strip them.
import importlib, sys, tomllib
from pathlib import Path


def load_agent(agent_dir):
    root = Path(agent_dir)
    agent = tomllib.loads((root / "agent.toml").read_text(encoding="utf-8"))
    sys.path.insert(0, str(root))                               # agent's helper files import each other by name
    agent["turn"] = importlib.import_module("turn").turn
    has_model = (root / "model.py").exists()                    # optional: most agents do not record model
    agent["model"] = importlib.import_module("model").model if has_model else (lambda _: agent.get("model_default", ""))
    return agent
