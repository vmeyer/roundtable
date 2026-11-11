# Party Mode — design

> Renamed to **roundtable** in v0.2.0 (agent `roundtable:panelist`, project dir `.roundtable/`).

**Date:** 2026-11-11
**Status:** Approved design, pending implementation plan
**Repo:** `github.com/vmeyer/party-mode` (public, MIT) — distributed via the `vmeyer/claude-plugins` marketplace

## Problem

When we work through a topic (architecture, a review, a go-live, a product decision), one assistant voice tends
to converge on a single, agreeable answer. We want several distinct perspectives in the room that actually
disagree, so blind spots surface before a decision is made.

BMAD's party mode (`bmad-code-org/BMAD-METHOD`, `skills/bmad-party-mode`, MIT) does this well conceptually, but it
depends on BMAD's installer, a `_bmad/` project folder, `uv`-run Python scripts and a layered TOML config. We want
the idea, not the dependency: our own plugin, our own personas written from scratch, plain Markdown only,
usable on the host and inside copilot-sandbox, with Copilot CLI and Claude Code.

## Goals

- A `party-mode` skill that runs a multi-persona round-table as one woven conversation with the user.
- Each persona that speaks is backed by its own **real, independent subagent**, spawned on its first turn and kept
  for the session (one mind voicing every persona is only a fallback).
- Our own persona pool covering: customer focus, architecture, security, engineering excellence, pragmatism,
  operations/SRE, testing/QA, plus three conversation helpers.
- Named rooms (curated casts + scene) per topic type; summon any pool persona by name.
- Optional per-room memory and an optional end-of-session note, both stored in the project under `.party/`.
- Zero runtime dependencies beyond the plugin standard and a harness that can spawn subagents.
- Long-lived: versioned, validated in CI, no third-party repos at runtime.

## Non-goals

- No BMAD compatibility layer, no `_bmad/` folder, no TOML config, no Python/uv at runtime.
- No HTML keepsake, no agent-team mode, no voting or automatic "the room decides".
- No persona authoring wizard in v1 (projects edit `.party/personas.md` / `.party/rooms.md` by hand).
- No sandbox-specific code beyond one line in `image/plugins/preinstalled-plugins.txt`.

## Repository layout

```
party-mode/
├── .claude-plugin/plugin.json        name, description, version, author, license, homepage, repository
├── skills/party-mode/
│   ├── SKILL.md                      orchestrator: activation, round loop, party rules, wrap-up
│   └── references/
│       ├── personas.md               the persona pool
│       ├── rooms.md                  named rooms (scene + members + memory flag)
│       └── memory.md                 memory file format and read/write rules
├── agents/party-guest.md             the single participant agent
├── tests/validate.sh                 structural validation (bash + python3 stdlib)
├── .github/workflows/validate.yml    runs tests/validate.sh on push / PR
├── docs/superpowers/specs/           this document
├── CHANGELOG.md
├── LICENSE                           MIT
└── README.md                         install (Copilot CLI, Claude Code, sandbox), usage, customization
```

Skill and agent text is English (like the other vmeyer plugins). Personas always **speak the user's language**.

## Personas

### File format (`personas.md`)

One entry per persona, a level-2 heading with the code, followed by a fixed bullet list. Human-readable and
machine-checkable:

```markdown
## architect
- name: Henrik
- icon: 🏛️
- role: Software Architect
- voice: Calm, whiteboard-style; lays out trade-offs instead of verdicts; draws boxes in words.
- cares_about: Boundaries, coupling, operability, long-term cost, boring technology.
- pushes_back_on: Shortcuts that leak across boundaries; hype-driven tech choices.
- signature_question: "What's the blast radius if this part fails?"
- friction: pragmatist (shortcuts), ops (complexity he adds)
```

Required fields: `name`, `icon`, `role`, `voice`, `cares_about`, `pushes_back_on`, `signature_question`,
`friction`. `friction` lists other persona codes (with an optional reason in parentheses) or `none`; every listed
code must exist. Codes are lowercase kebab-case and unique.

### Pool (v1, 10 personas)

| Code | Icon | Name | Role | Core stance / signature question | Friction |
|---|---|---|---|---|---|
| `customer` | 🧭 | Kira | Customer focus | Speaks for end users and the paying client; hates features nobody asked for. "Who is better off on Monday?" | security, architect |
| `architect` | 🏛️ | Henrik | Software architect | Boundaries, coupling, operability, long-term cost. "What's the blast radius?" | pragmatist, ops |
| `security` | 🔐 | Nadia | Security | Names the concrete attack path; data protection/GDPR, secrets, supply chain. Never "might be insecure". | pragmatist, customer |
| `craft` | 🛠️ | Jonas | Engineering excellence | Tests, simplicity, honest names, review discipline — quality from the inside. "Show me the test." | pragmatist, testing |
| `pragmatist` | ⏱️ | Mila | Pragmatist | Counts in weeks and euros; sorts every concern into "stops the release" or "can wait"; cost of waiting, small undoable steps. "Does this change what we ship this month?" | architect, security, craft, ops |
| `ops` | 📟 | Sven | Operations / SRE | Monitoring, runbooks, rollback, capacity, on-call. "How do we notice at 3 a.m. — and roll back?" | architect, pragmatist |
| `testing` | 🧪 | Lea | Testing / QA | Behaviour from the outside: risk-based testing, edge cases, acceptance criteria, test data. "What happens when a user does this in the wrong order?" | craft, pragmatist |
| `evidence` | 🔬 | Theo | Reality check | Asks for the number behind every adjective; says "we don't know yet" and proposes a cheap way to find out. "What's the number behind that?" | none |
| `contrarian` | 🎭 | Ruth | Devil's advocate | Argues properly for the option the room just dismissed, then steps back and leaves the call with the user. | none |
| `options` | 🔀 | Pablo | Reframer | Looks for the problem behind the problem; offers one small alternative at a time and lets go without a fight. "What if the real problem is something else?" | none |

The full persona text (voice, cares_about, pushes_back_on, …) is written during implementation following this table.
It is original text, not copied from BMAD.

## Rooms

### File format (`rooms.md`)

```markdown
## architecture
- name: Architecture Review
- members: architect, security, ops, pragmatist, contrarian
- memory: false
- scene: A whiteboard session on a proposed design. Henrik owns the pen, Sven keeps asking about the pager, ...
```

Required fields: `name`, `members` (3–5 existing persona codes), `memory` (`true`/`false`), `scene`.

### Rooms (v1)

| Id | Name | Members | Purpose |
|---|---|---|---|
| `round-table` (default) | Round Table | customer, architect, security, craft, pragmatist | General topics; the five core perspectives |
| `architecture` | Architecture Review | architect, security, ops, pragmatist, contrarian | Designs and technical direction |
| `code-review` | Code Review | security, craft, testing, pragmatist | Each reviews independently first, then they argue |
| `release` | Go-Live Check | ops, testing, security, pragmatist, customer | Readiness for production |
| `decision` | Decision Room | options, evidence, contrarian, pragmatist, customer | Hard choices; no voting, the user decides |
| `product` | Product & Customer | customer, pragmatist, architect, options | Scope, value, priorities |

All rooms default to `memory: false`.

### Project overrides

If the project contains `.party/personas.md` and/or `.party/rooms.md` (same format), they are loaded after the
plugin's files. An entry with an existing code/id **replaces** the built-in one as a whole (all required fields must be present —
copy the built-in entry and edit it); a new code/id is **added**.
This is how a project adds its own personas, re-tunes a room, or turns memory on permanently for a room.

## Invocation

- Natural language: "party mode", "round table", "let's get several perspectives on this".
- Slash form: `/party-mode [--room <id>] [--remember] [topic]`.
- Ad hoc: naming personas ("bring in Nadia and Sven") summons them from the pool into the current room;
  an inline list of names at start ("party mode with Kira, Lea and Mila") forms an ad-hoc room;
  "send <name> home" releases a guest.
- Unknown room id → show available rooms and ask.

## Round flow (orchestrator, `SKILL.md`)

1. **Load.** Read `references/personas.md` and `references/rooms.md`, then project overrides from `.party/`.
   Resolve the room (`--room`, inline cast, or `round-table`). Memory is on if `--remember` was passed or the
   room has `memory: true`; if on and `.party/memory/<room>.md` exists, read it (see Memory).
2. **Welcome.** Show the cast (icon, name, one-line role) and mention that other rooms exist. If the topic was
   given at launch, run the first round in the same response; otherwise ask for it. The host gathers material
   itself (e.g. `git diff` / `git show`, relevant paths), because guests cannot run commands.
3. **Spawn guests lazily.** One `party-guest` subagent per persona in the room, spawned the first time that guest
   is picked to speak, with the first brief and the full transcript so far. A guest not yet spawned simply
   hasn't spoken.
   - The cast is **standing**: reuse the same agent for that persona all session (Copilot CLI: background agent
     + follow-up messages; Claude Code: resume the subagent / `SendMessage`).
   - Only if the harness cannot continue a subagent, spawn fresh each time the guest speaks, with the full brief
     and transcript.
4. **Brief per guest:** the persona entry, the room scene, the topic, a `Material:` line (paths to read, a pasted
   diff or excerpt, or a summary of what was discussed before party mode; omitted if none), the **whole room
   transcript so far** (every guest hears everything, including rounds it sat out), and a `Rules:` line with the
   form constraints (speak only as the persona, 1–3 sentences unless the user asked for depth, react to what was
   just said, no summaries, never write files, never mention being an agent) so they hold even with a generic
   subagent or inline voicing. Follow-up briefs carry the turns the guest has not received yet, plus an optional
   `Room update:` block when something changed (room and scene, who joined or left, memory lines, answer
   language). Substance and reasoning are not scripted.
5. **Each round:** after the user's turn, pick **2–4 speakers** (vary the spotlight; not everyone every round).
   Run first takes in parallel; optionally run one sequential rebuttal pass so someone answers another's actual
   words. Weave the replies into **one** exchange, turns formatted `{icon} **{name}:**`, reordered so rebuttals
   follow what they rebut, with light connective phrasing — never altering what a persona argued and never
   paraphrasing them in third person. End the round with a persona addressing the user.
6. **Repeat** until the user signals they're done. Answering the opening question does not end the party.

### Party rules (written in our own words in `SKILL.md`)

- Reads like people talking: short turns, reactions, momentum — not a stack of memos.
- Voices are uneven and recognisable without their names; the spotlight moves.
- Real disagreement; the orchestrator does not reconcile or tie a bow. No manufactured consensus.
- Pull the user in: personas address and challenge the user directly.
- Disagreement has to earn something: a point none of the guests had at the start.
- Relationships accrue within the session (callbacks, alliances, running bits).
- No summaries or takeaways unless asked; when the room goes flat or circles, change the setup (invite a guest,
  say plainly where the room is stuck, ask the user) instead of forcing it.
- Stay inside the scene: never talk about subagents, spawning or other machinery.

## Participant agent (`agents/party-guest.md`)

- Frontmatter: `name: party-guest`, `description`, read-only tools (read/glob/grep/web search/web fetch), no
  write or shell-mutation tools, no pinned model (inherits the harness default).
- Body: how to be a guest — become the persona given in the brief, answer only as that persona, honour the
  scene, keep the length cap, react to the transcript, disagree when the persona would, never summarise the
  room, never speak for other personas, verify anything time-sensitive via web search instead of guessing.
  `Material:` and `Room update:` are binding context.
- Appears in Copilot CLI as `party-mode:party-guest`; Claude Code exposes plugin agents the same way.

## Memory (`references/memory.md`)

- Off by default. On with `--remember` or `memory: true` on the room.
- File: `.party/memory/<room-id>.md` (ad-hoc rooms have no memory). Append-only, one line per entry:
  `- 2026-11-11 · dynamic · Mila and Nadia clashed over deferring the pentest; unresolved.`
  Types: `dynamic`, `moment`, `callback`, `outcome`.
- Read on start (and on a room switch). If the file exceeds ~150 lines, a subagent distils it into a short
  "where things stand" brief instead of loading it raw.
- Write silently when a memorable beat lands, plus a floor entry after the first real exchanges, plus a top-up
  at wrap-up. Never announce writes. A failed write is skipped silently.
- Forget = delete the file. Correct = append a superseding entry.

## Wrap-up

When the user signals done:

1. Read back the key takeaways in chat (positions, tensions, open points, decision if any).
2. Offer a note: `.party/notes/<YYYY-MM-DD>-<topic-slug>.md` with room, cast, topic, positions per persona,
   open questions, decision (if the user made one). Written only on yes; if the write fails, say so in one line.
3. If memory is on, top up `.party/memory/<room>.md`.
4. Release standing agents; return to normal mode.

Whether `.party/` is committed is the project's choice (README suggests adding `.party/memory/` to
`.gitignore` if it shouldn't be shared).

## Error handling

- A guest fails or times out → the persona "steps out" for that round in the fiction; the round continues; it is
  respawned next round (standing cast: resumed or respawned once, then dropped with a one-line note).
- Harness cannot spawn subagents at all → the orchestrator voices all personas inline and says so once.
- Override file malformed (missing field, unknown member code) → mention it once, skip the broken entry, continue
  with built-ins.
- Unknown persona name summoned → offer the closest pool match.
- A requested note cannot be written → report it in one line; memory write failures stay silent.

## Distribution & sandbox integration

- `vmeyer/party-mode` on github.com, public, MIT; semver in `plugin.json`, git tag per release, `CHANGELOG.md`.
- Entry in `vmeyer/claude-plugins/.claude-plugin/marketplace.json` (same shape as `diagram-skills`).
- Host: `copilot plugin install party-mode@vmeyer-plugins`; Claude Code: `/plugin install party-mode@vmeyer-plugins`.
- copilot-sandbox: add `party-mode@vmeyer-plugins` to `image/plugins/preinstalled-plugins.txt` (+ README plugin
  table). Existing volumes pick it up on the next start (the seed installs missing plugins). `.party/` lands in
  the mounted project, so notes and memory survive the ephemeral container.

## Testing

- `tests/validate.sh` (bash + python3 standard library only):
  - `plugin.json` is valid JSON with required keys; version is semver.
  - `SKILL.md` and `agents/party-guest.md` have valid frontmatter (`name`, `description`).
  - `personas.md`: unique kebab-case codes, all required fields present, `friction` codes exist.
  - `rooms.md`: unique ids, required fields, 3–5 members, every member code exists, `memory` is boolean,
    the default room `round-table` exists.
  - Validator also accepts a path to a project `.party/` dir to check overrides.
- GitHub Action runs the validator on push and pull request.
- Manual smoke test per release, once in Copilot CLI and once in Claude Code: start `round-table` on a small
  topic → guests are spawned as subagents, turns use `{icon} **{name}:**`, ≤4 speakers per round, a persona
  addresses the user, `--remember` writes `.party/memory/round-table.md`, wrap-up offers a note.
- Sandbox: after adding the plugin line, `make test` stays green and a fresh volume lists `party-mode` in
  `copilot plugin list`.

## Resolved during planning

- Agent tool restriction: `tools: Read, Grep, Glob, WebSearch, WebFetch` works in both harnesses — Claude Code
  uses these names natively; Copilot CLI maps them to its `read`, `search` and `web` aliases and ignores unknown
  names.
- Standing cast: both harnesses can continue a running subagent — Copilot CLI via background agents and follow-up
  messages, Claude Code by resuming a custom subagent (`SendMessage`). Spawning fresh each time a guest speaks
  is only the fallback.
