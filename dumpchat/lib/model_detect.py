#!/usr/bin/env python3
# lib/model_detect.py — detect Claude model from JSONL + format it human-friendly
# NEVER DELETE COMMENTS — explain every non-obvious line. Update comments with the code.
import json

def detect_model(path):
    """Scan JSONL for the last assistant message that carries a model field."""
    model = None
    try:
        with open(path) as f:
            for line in f:
                if '"model"' not in line:   # fast pre-filter before full parse
                    continue
                try:
                    d = json.loads(line)
                except Exception:
                    continue
                m = d.get("message", {})
                if m.get("role") == "assistant" and m.get("model"):
                    model = m["model"]       # keep overwriting — last seen = most recent
    except Exception:
        pass
    return model

def friendly_name(mid):
    """'claude-sonnet-4-6' → 'Sonnet 4.6'  |  None → 'Claude'"""
    if not mid:
        return "Claude"
    s = mid[7:] if mid.startswith("claude-") else mid
    fams = {"opus", "sonnet", "haiku", "fable", "instant"}
    fam, nums = None, []
    for p in s.split("-"):
        if p in fams:
            fam = p.capitalize()
        elif p.isdigit() and len(p) <= 2:
            nums.append(p)
    return f"{fam} {'.'.join(nums)}" if fam and nums else mid
