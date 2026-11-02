---
name: dumpboth
description: Dump BOTH .md (dumpchat) and .jsonl (dumpjsonl) for the current session on the same matching name, detect desync between existing dumps, and view them in DBV (the DumpBoth Viewer app)
---

# Dump Both to Old Chats

> ## ⛔ NEVER DUMP VIA SUBAGENT (severity ∞)
> Run this command in the **parent session being dumped**. Never `Task` dumpboth/dumpchat/dumpjsonl — a worker dumps the wrong chat.

## EXECUTE IMMEDIATELY

```bash
~/.claude/skills/dumpboth/dumpboth.command [cursor|devin] [home] [append -suffix] [uuid] [target_dir]
```

Pass through the same args `/dumpchat` and `/dumpjsonl` accept, plus **`cursor`** for
Cursor IDE agent sessions and **`devin`** for Devin CLI sessions. Produces two files
with the **identical stem** — `oldchatN[-suffix].md` and `oldchatN[-suffix].jsonl` —
never two different numbers, because both underlying dumpers are forced onto one
number computed ONCE up front (see `lib/counter/shared_next_number.py`).

Every dump is ALSO tagged with an 8-hex random suffix (see `lib/tag/generate_tag.py`)
even when the user gives a human label — the tag is appended after the label
(`-mylabel-b4f9a2c1`), so a pair can always be matched by tag alone even if a future
independent `/dumpchat`/`/dumpjsonl` call ever causes the numbers to drift apart.

## Detect — find and fix desync

```bash
~/.claude/skills/dumpboth/dumpboth.command detect [home|target_dir]
```

Scans `Old Chats/` for every `oldchatN[-suffix].{md,jsonl}`, reports:
- numbers with only one extension present (an "orphan")
- numbers where both exist but their tags don't match (two unrelated dumps sharing a number)

**When there's exactly one easy-to-fix orphan, proactively suggest filling it** —
don't just report the gap, offer to close it (per user directive 2026-08-18). Detect
prints the exact command under "Easy fixes available" when the gap is cheaply
correctable:
- **jsonl-only** → always fillable: renders the `.md` straight from the jsonl already
  in hand via `dumpchat/lib/parse_session.py`.
- **md-only** → fillable only if the `.md`'s own `Source: <path>` footer still points
  at a readable jsonl (a plain `cp`). If that source is gone, this is NOT the easy
  case — nothing is suggested; don't send the user on a `/find-claude-chat` hunt
  unless they ask.

Surface the suggested command and ask before running it (per Layer Discipline —
detecting/suggesting ≠ acting).

**Unfixable gaps → `db/known-lost/<number>.toml`.** When an orphan's source is
provably gone (searched, not found), never fabricate the missing file. Drop a marker
(`file`, `missing`, `source`, `reason`, `accepted`) and detect lists it under
"Known lost, accepted" instead of as desync. Move marker to Trash to re-flag it.
Loader: `lib/detect/load_known_lost.py`.

## Note storage — db/, folder per dump, file per note

Human notes NEVER go inside the `.jsonl` (it is canonical training data; modifying it
would distort it). They live in this skill's own database:

```
db/<dump-stem>/<turn-uuid>.toml     one file = one note
```

e.g. `db/oldchat2-dumpboth-919b69e1/c758cd22-....toml`. Keyed by the turn's jsonl uuid so
notes survive a re-dump. Plain TOML, hand-editable. Clearing a note moves its file to the
Trash (never `rm`). Verified 2026-08-18: writing a note leaves the `.jsonl` sha256 identical.

## DBV — the viewer app

`~/.claude/skills/dbv/DBV/` is a small SwiftUI app (`swift build`, installs to `/Applications/DBV.app`)
that renders `.jsonl` files as a clean chat transcript instead of raw JSON lines.
Format parsers are dropped under `~/.claude/skills/dbv/DBV/Sources/DBVCore/Parsing/Formats/` — Claude and
Cursor ship as two folders; adding a dialect is a new folder, not a dump rewrite.
Rebuild and usage: `/dbv` (`~/.claude/skills/dbv/SKILL.md`).

- **Launched standalone** (Dock/Applications) → browser mode: sidebar lists every
  dump pair found in `~/Old Chats/` by name, selecting one shows its transcript.
  An incomplete pair is flagged right in the sidebar.
Notes live BETWEEN bubbles: hover a gap to reveal a hairline "＋ Note" affordance, click
to type, ⌘↩ to save. A "Notes" toolbar button opens a timeline inspector listing every
note in transcript order on a rail; clicking a row scrolls straight to it. Turns can also
be starred (yellow rail), and the search box matches note text as well as transcript text.
Per-turn metadata now shown from data already in the dump: wall-clock time, token cost
(cache read / output), driving skill, and error/denial flags.

- **Opened on a specific `.jsonl`** (Finder double-click, "Open With", or as the
  system default handler) → single-file mode: just that transcript, full window,
  **no sidebar** — this is deliberate, not a bug, for files opened outside the
  dumpboth browser (per user directive 2026-08-18).

DBV is registered as the **default app for `.jsonl`** system-wide (via
`~/.claude/skills/dbv/DBV/Tools/Info.plist` + `duti -s com.TowelWare.DBV .jsonl all` in `~/.claude/skills/dbv/DBV/build.command`).

Rebuild after any Swift change:
```bash
~/.claude/skills/dbv/DBV/build.command
```

## Architecture (`/split-files` discipline)

One function per file, folder-per-concern:

| Path | Role |
|---|---|
| `dumpboth.command` | thin bash orchestrator — wires the pieces, no real logic |
| `../dumpchat/cursor-session-find.sh` | shared Cursor main-session resolver (md + jsonl cursor dumps) |
| `../dumpjsonl/dumpjsonl-cursor.command` | verbatim Cursor jsonl export (pairs with dumpchat-cursor) |
| `../dumpchat/dumpchat-devin.command` | Devin CLI readable-md dump (dispatch → `lib/devin/export`) |
| `../dumpjsonl/dumpjsonl-devin.command` | verbatim Devin jsonl export (dispatch → `lib/devin/export-jsonl`) |
| `../dumpchat/lib/devin/*` | Devin pipeline: `locate-db`→`select-session`→`read-messages`/`read-raw`→render. Store: `~/.local/share/devin/cli/sessions.db` (SQLite `sessions`+`message_nodes`); current session = most recent `last_activity_at` |
| `lib/tag/generate_tag.py` | mint the matching 8-hex tag |
| `lib/counter/shared_next_number.py` | compute the ONE number both dumps share |
| `lib/detect/scan_pairs.py` | pure scan: group files by number+tag |
| `lib/detect/report_desync.py` | pure render: orphans + tag mismatches as text |
| `lib/detect/fix_jsonl_only.py` | suggest the always-fillable jsonl→md fix |
| `lib/detect/fix_md_only.py` | suggest the conditionally-fillable md→jsonl fix |
| `lib/detect/suggest_fix.py` | thin combiner of the two fix suggesters |
| `lib/detect/cli.py` | wires scan+report+suggest for `detect` mode |
| `~/.claude/skills/dbv/DBV/Sources/DBVCore/` | pure model/parsing (DumpPair, jsonl parser) — no UI |
| `~/.claude/skills/dbv/DBV/Sources/DBVApp/` | SwiftUI views + AppDelegate (file-open routing) |

`dumpchat.command` and `dumpjsonl.command` both gained a `DUMP_FORCE_NUM` env-var
override (backward compatible — unset behaves exactly as before) so `/dumpboth` can
force them onto the same number without touching their normal standalone behavior.

## Triggers

- `/dumpboth`, `/dumpboth home append -label`, `/dumpboth <uuid>`
- `/dumpboth cursor` — Cursor IDE agent session. Lands in `~/Old Chats/`, never the shell cwd. A named directory is the only other destination.
- `/dumpboth cursor mylabel` — shorthand for `cursor append -mylabel` (suffix + auto tag)
- `/dumpboth cursor home append -label` — Cursor session to `~/Old Chats/`
- `/dumpboth cursor <uuid>` — specific Cursor session by id
- `/dumpboth devin` — Devin CLI session (md via dumpchat-devin + raw jsonl via dumpjsonl-devin); auto-selects the current session
- `/dumpboth devin home` — Devin session to `~/Old Chats/`
- `/dumpboth devin mylabel` — shorthand for `devin append -mylabel` (suffix + auto tag)
- `/dumpboth detect` — check for desync, get fix suggestions
- User wants both formats at once, or asks "did md and jsonl match?"

Publishing: upload this real skill folder, with private info removed. Never publish rewritten copy.
