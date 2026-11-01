#!/usr/bin/env python3
# lib/headers.py — per-CLI ASCII art header block
# NEVER DELETE COMMENTS — explain every non-obvious line. Update comments with the code.
from model_detect import detect_model, friendly_name

def get_header(cli_type, session_file, target_dir):
    """Return list of lines to print at the top of the dump file."""
    model_str = friendly_name(detect_model(session_file)) + " · Claude Code"
    _H = {
        "claude":   (" ▐▛███▜▌   Claude Code",
                     "▝▜█████▛▘  " + model_str),
        "codex":    (" ┌─────┐   Codex CLI",
                     "│ ◉ ◉ │  OpenAI"),
        "gemini":   (" ☆ ☆ ☆ ☆ ☆   Gemini CLI",
                     "  ☆ ☆ ☆    Google"),
        "kilo":     (" ╔════╗   Kilo Code",
                     "║ ☰ ║  Kilo · Multi-Provider"),
        "opencode": (" ╭────╮   OpenCode",
                     "│▲▲▲│  OpenCode AI"),
    }
    default = ("■ ■ ■ ■ ■   AI CLI Session",
               "  ■ ■ ■    Unknown Provider")
    h = _H.get(cli_type, default)
    return [h[0], h[1], f"  ▘▘ ▝▝    {target_dir}", ""]
