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
| `dumpboth.command` | thin orchestrator — sources 7 lib files, no inline logic |
| `lib/args/parse_mode.sh` | detect cursor/devin mode + shorthand suffix |
| `lib/args/parse_target.sh` | parse home/append/uuid/dir from args |
| `lib/args/resolve_target.sh` | cursor-home enforcement + scam-dir block |
| `lib/detect/dispatch.sh` | detect mode early-exit |
| `lib/tag/build_suffix.sh` | NEXT_NUM + TAG + FINAL_SUFFIX computation |
| `lib/execute/resolve_commands.sh` | resolve 6 child dumper command paths |
| `lib/execute/dispatch_pair.sh` | run chat+jsonl pair, capture exit codes |
| `lib/execute/check_results.sh` | exit 1 if both failed, print summary |
| `lib/tag/generate_tag.py` | mint the matching 8-hex tag |
| `lib/counter/shared_next_number.py` | compute the ONE number both dumps share |
| `lib/detect/scan_pairs.py` | pure scan: group files by number+tag |
| `lib/detect/report_desync.py` | pure render: orphans + tag mismatches as text |
| `lib/detect/fix_jsonl_only.py` | suggest the always-fillable jsonl→md fix |
| `lib/detect/fix_md_only.py` | suggest the conditionally-fillable md→jsonl fix |
| `lib/detect/suggest_fix.py` | thin combiner of the two fix suggesters |
| `lib/detect/cli.py` | wires scan+report+suggest for `detect` mode |
| `dumpchat/dumpchat.command` | thin Claude md dumper (sources shared libs) |
| `dumpchat/dumpchat-opencode.command` | thin OpenCode md dumper |
| `dumpchat/dumpchat-cursor.command` | thin Cursor md dumper |
| `dumpchat/dumpchat-gemini.command` | thin Gemini md dumper |
| `dumpchat/dumpchat-codex.command` | thin Codex md dumper |
| `dumpchat/dumpchat-kilo.command` | thin Kilo md dumper |
| `dumpchat/dumpchat-devin.command` | Devin CLI md dump (dispatch → `lib/devin/export`) |
| `dumpchat/cursor-session-find.sh` | shared Cursor main-session resolver |
| `dumpchat/dumpchat-session-find.sh` | 8-line shim sourcing lib/session/resolve.sh |
| `dumpchat/lib/session/resolve.sh` | orchestrator: exact ID only (uuid arg or `CLAUDE_CODE_SESSION_ID`); refuses otherwise |
| `dumpchat/lib/session/child_guard.sh` | CHILD flag + no ID → refuse; CHILD flag + ID → trust ID |
| `dumpchat/lib/session/resolve_by_id.sh` | UUID lookup across all CLI dirs |

> **Claude dumps NEVER pick "newest" JSONL (2026-11-05).** Old newest/recent-mtime
> fallbacks (`resolve_claude.sh`, `resolve_fallback.sh`, `claude_candidates.sh`) dumped
> previous chat instead of current one (oldchat694 = duplicate of 693). Removed.
| `dumpchat/lib/session/finder_find_by_id.sh` | Finder AppleScript EPERM fallback |
| `dumpchat/lib/session/realpath.sh` | portable realpath via python3 |
| `dumpchat/lib/session/find_opencode.sh` | find newest OpenCode session |
| `dumpchat/lib/session/find_codex.sh` | find newest Codex session |
| `dumpchat/lib/session/find_gemini.sh` | find newest Gemini session |
| `dumpchat/lib/session/find_kilo.sh` | find newest Kilo session |
| `dumpchat/lib/shared/parse_simple_args.sh` | basic home/append/target parsing |
| `dumpchat/lib/shared/parse_uuid_args.sh` | args with UUID support |
| `dumpchat/lib/shared/setup_old_chats.sh` | block scam dir + mkdir Old Chats |
| `dumpchat/lib/shared/next_number.sh` | compute next oldchat number |
| `dumpchat/lib/shared/export_path.sh` | build EXPORT_FILE from number+suffix+ext |
| `dumpchat/lib/parsers/opencode.py` | OpenCode JSONL parser |
| `dumpchat/lib/parsers/cursor.py` | Cursor IDE parser |
| `dumpchat/lib/devin/*` | Devin pipeline: locate-db→select-session→read→render |
| `dumpjsonl/dumpjsonl.command` | thin Claude jsonl dumper |
| `dumpjsonl/dumpjsonl-cursor.command` | thin Cursor jsonl dumper |
| `dumpjsonl/dumpjsonl-devin.command` | Devin jsonl export |

`dumpchat.command` and `dumpjsonl.command` use `DUMP_FORCE_NUM` env-var
override so `/dumpboth` can force them onto the same number.

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

Publishing: before upload, this skill must have no leaks (private paths, personal names, emails, drive paths, private chat notes, blocked-folder paths, machine-only rules). Remove only the leaks, then upload this real skill folder as it is. This repo is the dumpboth skill only. dumpchat and dumpjsonl stay nested here. dbv and dumpconvert are their own repos. No rewritten copy, no invented skills/ parent, no extra release or staging folders.
