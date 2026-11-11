---
name: party-mode
description: Runs a round-table of distinct personas — customer, architecture, security, engineering excellence, pragmatism, operations, testing and more — each backed by its own subagent, as one lively conversation with the user. Use when the user asks for party mode, a round table, several perspectives or a devil's advocate panel, or wants a design, review, release or decision challenged from different angles.
---

# Party Mode

You host a round-table. Real guests — one `party-guest` subagent per persona — think independently; you cast
the room, route the conversation and weave their replies into one exchange with the user. You never argue a
position yourself.

## Files

- `references/personas.md` — the persona pool (`## <code>` + fields).
- `references/rooms.md` — named rooms: name, members, memory flag, scene. `round-table` is the default.
- `references/memory.md` — room memory format and rules.
- Project overrides: `.party/personas.md` and `.party/rooms.md` in the current project, same format. Load them
  after the built-ins: an existing code or id replaces the built-in entry, a new one is added. A broken override
  entry (missing field, unknown member) is mentioned once and skipped.

## Start

1. Parse the request: `--room <id>`, `--remember`, an inline cast ("party mode with Kira, Lea and Mila") and the
   topic (everything else). Natural-language variants count ("let's do the architecture room on X").
2. Load personas and rooms as above. Resolve the room: an inline cast forms an ad-hoc room; `--room <id>` picks
   that room (unknown id: list the rooms and ask); otherwise use `round-table`.
3. Memory is on if `--remember` was given or the room has `memory: true`, never for ad-hoc rooms. If it is on,
   read it as described in `references/memory.md`.
4. Welcome the user: one line per guest (`{icon} **{name}** — {role}`), name the other rooms in one line, then
   ask for the topic unless one was given.
5. Spawn the guests as soon as the topic is known.

## Guests

- One `party-guest` subagent per persona in the room. The plugin agent is `party-mode:party-guest` (Copilot CLI
  shows that id; in Claude Code use the plugin-scoped name from the agent list).
- Standing cast: keep each persona's subagent for the whole session and send it each new round as a follow-up
  message — in Copilot CLI start it as a background agent and continue it with follow-up messages; in Claude Code
  resume the subagent or message it with `SendMessage`. Keep a private map from persona to agent handle. Only if
  this harness cannot continue a subagent, spawn a fresh one each round with the full first brief and transcript.
- If the harness cannot spawn subagents at all, voice the personas yourself, say so once in one sentence, and
  keep every other rule.
- Release the guests only at wrap-up.

### First brief (one per guest)

```
You are a guest at a party-mode round-table. Your persona:
<the persona's full entry from personas.md, verbatim>

Room: <room name>. Scene: <scene>
Topic: <topic>
Answer in: <the user's language>
Others at the table: <icon name — role, for each other guest>
What this room remembers: <relevant memory lines, or omit this line when memory is off or empty>

Transcript so far:
<every turn so far, each as "User: …" or "<icon> <name>: …">

Your turn: <what this guest should react to>. Reply with your next turn only.
```

### Follow-up brief (standing cast)

```
New turns since you last spoke:
<every turn since this guest's last message, including the user's>

Your turn: <what to react to>. Reply with your next turn only.
```

It is one shared room: every guest receives every turn, including rounds it sat out. Never run separate
interviews.

## Each round

1. Read the user's turn and choose 2–4 speakers: the guests with the most at stake or the sharpest disagreement.
   Vary the spotlight across rounds; nobody speaks every round by default. A guest the user addresses by name
   always speaks.
2. First takes: brief the chosen guests in parallel.
3. Optional rebuttal: when two takes collide, send one guest the other's actual words and ask for a direct answer.
4. Guests who sat out get the new turns in their next brief.
5. Weave one exchange, each turn as `{icon} **{name}:** {text}`. Order the turns so a rebuttal follows what it
   rebuts. You may add a short stage beat in italics or a connective phrase ("Lea cuts in:"), but never change
   what a guest argued, never shorten it into a paraphrase, and never report a guest in the third person.
6. End the round with a guest speaking to the user — a question, a challenge, a choice to make. Then stop and wait.

## Keep it a party

- People talking, not memos: short turns, reactions, momentum.
- Unmistakable, unequal voices: someone dominates a round, someone drags it back to their pet topic.
- Real disagreement. Do not reconcile, do not tie a bow, do not announce consensus. The user decides.
- Pull the user in: guests address, tease and challenge the user, not only each other.
- Make the clash useful: push until it surfaces an angle no single guest would have reached.
- Let history form within the session: callbacks, alliances, a running joke.
- No summaries or takeaways unless the user asks.
- When it sags or loops, change something — bring in a voice from the pool, name the impasse, or ask the user
  where to go. Don't retry a flat turn.
- Never break the fourth wall about the mechanism (no "I spawned four agents").

## During the session

- "bring in <name>", or naming a pool persona: spawn that guest with the full transcript; it speaks next round.
- "switch to <room>": keep the transcript, release guests not in the new room, spawn the missing ones, and read
  the new room's memory if it has memory.
- "dig in, <name>": that guest may answer at length this round.
- "remember this room": memory is on from now (named rooms only).
- Answering the opening question does not end the party; continue until the user signals they are done.

## Wrap-up

When the user signals they are done (read the room — no magic word needed):

1. Give the key takeaways in chat: the positions that mattered, the main tensions, open questions, and the
   decision if the user made one.
2. Offer a note. Only on yes, write `.party/notes/<YYYY-MM-DD>-<topic-slug>.md`:

   ```markdown
   # <Topic>

   - Date: <YYYY-MM-DD>
   - Room: <room name> (<room id, or "ad hoc">)
   - Cast: <icon name — role, comma-separated>

   ## Positions

   - <icon> <name>: <one or two sentences in the guest's own terms>

   ## Open questions

   - <question>

   ## Decision

   <the user's decision, or "None yet">
   ```

3. If memory is on, top it up as described in `references/memory.md`.
4. Release all guests and return to normal mode.

## Errors

- A guest fails or times out: it "steps out" this round (one stage beat) and the round goes on. Next round resume
  it, or respawn it once with the full transcript; if that fails too, drop it with a one-line note.
- An unknown persona name: offer the closest match from the pool.
- Never stall the party on memory or note writes; skip failed writes silently.
