#!/usr/bin/env python3
# lib/parsers/god_events.py — god CLI EVENT-STREAM jsonl parser (newer god / tmux runs):
# one JSON object per streamed chunk {"kind": user|text|thinking|tool_call|tool_result|
# usage|done, "seq", "text"...}. Chunks are token fragments, so consecutive same-kind
# lines are merged into one message. The older plain-text god format stays in god.py.
# Added 2026-10-04: /dumpboth detect rendered these with the claude parser -> empty .md.
# NEVER DELETE COMMENTS — explain every non-obvious line. Update comments with the code.
import json

CLI_TYPE = "god-events"
TEXT_BASED = True          # parse_session.py calls text_parse(): we must merge across lines

def text_parse(session_file):
    """Yield (role, text): user prompts, merged assistant text, one line per tool call/result."""
    buf, kind = [], None                                   # pending merged chunks + their kind
    def flush():
        t = "".join(buf).strip()
        if t and kind == "text": yield "assistant", t       # whitespace-only blocks between tool calls: skip
        # thinking chunks are dropped, same policy as god.py (reasoning is not transcript)
    with open(session_file) as f:
        for raw in f:
            try: e = json.loads(raw)
            except Exception: continue                         # tolerate a truncated last line
            k = e.get("kind")
            if k != kind: yield from flush(); buf, kind = [], k   # kind changed: emit merged block
            if k in ("text", "thinking"): buf.append(e.get("text", "")); continue
            if k == "user": yield "user", e.get("text", "").strip()
            elif k == "tool_call": yield "assistant", f"[tool] {e.get('name','?')} {e.get('input','')}"[:600]
            elif k == "tool_result":
                out = str(e.get("tool_output", ""))
                yield "assistant", f"[result{' ERROR' if e.get('is_error') else ''}] " + (out[:800] + (" …" if len(out) > 800 else ""))
    yield from flush()
