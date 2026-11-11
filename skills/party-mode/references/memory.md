# Room memory

Memory lets a named room remember earlier sessions in this project. It is a short, append-only log, not a
transcript.

## When it is on

- The user passed `--remember`, said "remember this room", or the room has `memory: true` (set in the project's
  `.party/rooms.md`).
- Ad-hoc rooms (an inline cast) never have memory.

## File

`.party/memory/<room-id>.md` in the current project. Create `.party/memory/` with the first entry.

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
- Pass the relevant lines to each guest in its first brief under "What this room remembers:".
- Let memory shape the room in character: resume alliances and open threads, land callbacks when they fit.
  Never announce that anything was loaded and never recite it.

## Write

- After the first real exchanges: one entry on what the session is about and the opening dynamic.
- Whenever a memorable beat lands: a shift in the room, a decision, a line worth a callback.
- At wrap-up: the outcome and anything memorable not yet captured.
- Test every entry: would it colour a future session? If not, skip it. A handful of entries per session, never a
  recap.
- Writes are silent: never say "noted" or "I'll remember". If a write fails, skip it silently.

## Correct and forget

- Correct: append a new entry that supersedes the old one; the latest entry wins.
- Forget: delete `.party/memory/<room-id>.md`, or the whole `.party/memory/` directory.
