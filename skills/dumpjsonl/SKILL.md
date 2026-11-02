---
name: dumpjsonl
description: Export current session as RAW jsonl (verbatim, no md conversion) to Old Chats/ with auto-increment filename
---

# Dump JSONL to Old Chats

## EXECUTE IMMEDIATELY

When invoked, run this command **without any other logic or reimplementation**:

```bash
~/.claude/skills/dumpjsonl/dumpjsonl.command [args]
```

Pass any user-provided args directly. Do not inline the logic. Do not reimagine it.

## What it does differently from /dumpchat

`/dumpchat` converts the session to human-readable markdown. `/dumpjsonl` copies the
**actual, untouched jsonl transcript** — the exact file `/find-claude-chat` and
training pipelines read from `~/.claude/projects/`. No header, no footer, no
reformatting. What's dumped IS the chat, not a rendering of it.

Session discovery is shared with `/dumpchat` (same `dumpchat-session-find.sh`) so both
skills agree on which session is "current" — never reimplemented separately.

**Devin CLI:** `dumpjsonl-devin.command` dumps the current Devin CLI session verbatim.
Devin stores sessions in a SQLite DB (`~/.local/share/devin/cli/sessions.db`,
tables `sessions`+`message_nodes`), not a loose jsonl, so "verbatim" here means every
`message_nodes.chat_message` (all roles) emitted one JSON object per line, in node
order. Pipeline shared with `dumpchat-devin` via `../dumpchat/lib/devin/`. Usually
driven through `/dumpboth devin` (md + jsonl together).

## `home` / `append` — same interface as /dumpchat

```bash
/dumpjsonl                        # -> ./Old Chats/oldchat<N>.jsonl
/dumpjsonl home                   # -> ~/Old Chats/oldchat<N>.jsonl
/dumpjsonl home append -my-label  # -> ~/Old Chats/oldchat<N>-my-label.jsonl
/dumpjsonl <uuid>                 # dump a specific session by id
```

Numbering is independent from `/dumpchat`'s `oldchatN.md` counter — `.jsonl` files
scan their own `oldchat*.jsonl` glob, so the two dumps never collide or force each
other's sequence, even though they share the same `Old Chats/` directory.

## Triggers

Use when:
- User wants the actual/raw chat data, not a markdown rendering — e.g. for training,
  or to hand to `/find-claude-chat`-style tooling
- `/dumpjsonl`, `/dumpjsonl home`, `/dumpjsonl home append -suffix`
- User says "dump the real jsonl" / "dump the actual chat" / "raw dump"
