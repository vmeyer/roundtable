# Changelog

## 0.1.2 — 2026-11-11

- Skill: Copilot CLI hosts call `read_agent` with `wait: true` right after spawning and write no text between
  tool calls (that text is visible too), ignoring the task tool's "tell the user you're waiting" hint.
- Skill: a round is the first takes plus at most one rebuttal; a pool guest joins from the next round on.
- Skill: verbatim weaving keeps the guest's paragraph breaks.

## 0.1.1 — 2026-11-11

- Skill: explicit harness mechanics — Copilot CLI spawns guests with `task` (`mode: "background"`) and continues
  them with `write_agent` / `read_agent`; Claude Code uses the Agent tool and resume / `SendMessage`.
- Skill: tool calls, retries and errors stay invisible; no machinery talk in the reply.
- Skill: guest replies are woven verbatim; connective phrases and stage beats go on their own line.
- Skill: defined what releasing a guest means; releases are never announced.
- Skill: at most 4 speakers and one rebuttal per round; no staged rebuttal when all first takes agree.

## 0.1.0 — 2026-11-11

- Initial release: `party-mode` skill, `party-guest` subagent, 10 personas, 6 rooms
  (`round-table`, `architecture`, `code-review`, `release`, `decision`, `product`).
- Project overrides via `.party/personas.md` and `.party/rooms.md`.
- Optional room memory (`.party/memory/<room>.md`) and end-of-session notes (`.party/notes/`).
- Structural validator with self-tests and GitHub Actions workflow.
