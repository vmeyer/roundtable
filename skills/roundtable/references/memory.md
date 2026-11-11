# Room memory

Memory lets a named room remember earlier sessions in this project. It is a short, append-only log, not a
transcript.

## When it is on

- The user passed `--remember`, said "remember this room", or the room has `memory: true` (set in the project's
  `.roundtable/rooms.md`).
- Ad-hoc rooms (an inline cast) never have memory.

## File

`.roundtable/memory/<room-id>.md` in the current project. Create `.roundtable/memory/` with the first entry.

    # Memory: Round Table

    - 2026-11-11 · dynamic · Mila and Nadia clashed over postponing the pentest; unresolved.
    - 2026-11-11 · outcome · The user chose a feature flag for the billing rollout.
    - 2026-11-12 · callback · Sven's "pager at 3 a.m." line has become a running joke.

One line per entry: `- <YYYY-MM-DD> · <type> · <text>`. Types:

- `dynamic` — how guests relate: a clash, an alliance, who is cold with whom.
- `moment` — something memorable said or discovered.
- `callback` — a line or bit worth bringing back.
- `outcome` — a decision, a result, where a topic landed.

## Read

- At the start, and when switching into a room with memory, read the file if it exists.
- Up to about 150 lines: read it directly. Longer: have a subagent distil it into a short "where things stand"
  brief and use that instead.
- Pass the relevant lines to each guest in its first brief under "What this room remembers:". Guests already at
  the table when memory is read on a room switch, or turned on mid-session, get those lines in the `Room update:`
  block of their next brief.
- Let memory shape the room in character: resume alliances and open threads, land callbacks when they fit.
  Never announce that anything was loaded and never recite it.

## Write

- Once the session has found its topic: one entry saying what it is about and how the room started out.
- When something lands that people will remember: the room shifts, a decision falls, a line is worth repeating.
- At wrap-up: one closing entry with the result, plus anything worth keeping that has no entry yet.
- Test every entry: would it colour a future session? If not, skip it. A handful of entries per session, never a
  recap.
- Writes are silent: never say "noted" or "I'll remember". If a write fails, skip it silently.

## Correct and forget

- Correct: add a newer line that says what changed — the most recent line counts.
- Forget: delete `.roundtable/memory/<room-id>.md`, or the whole `.roundtable/memory/` directory.
