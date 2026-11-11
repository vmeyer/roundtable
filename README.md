# party-mode

A round-table of distinct personas for GitHub Copilot CLI and Claude Code. Each persona is backed by its own
subagent, so the voices think independently — and actually disagree — before you decide.

Inspired by the party-mode idea in BMAD-METHOD; all personas, rooms and instructions here are original, and the
plugin has no dependencies beyond the plugin standard.

## Install

**Copilot CLI**

```bash
copilot plugin marketplace add vmeyer/claude-plugins
copilot plugin install party-mode@vmeyer-plugins
```

**Claude Code**

```
/plugin marketplace add vmeyer/claude-plugins
/plugin install party-mode@vmeyer-plugins
```

**copilot-sandbox:** preinstalled (`image/plugins/preinstalled-plugins.txt`).

## Use

```
party mode — should we split the billing service?
/party-mode --room architecture Event sourcing for orders?
/party-mode --room release --remember Are we ready for Friday?
party mode with Kira, Lea and Mila: the new onboarding flow
```

Mid-session: "bring in Nadia", "switch to the decision room", "dig in, Sven", "remember this room".
Say you're done to get the takeaways and an optional note.

## Personas

| | Name | Role |
|---|---|---|
| 🧭 | Kira | Customer Advocate |
| 🏛️ | Henrik | Software Architect |
| 🔐 | Nadia | Security Engineer |
| 🛠️ | Jonas | Engineering Excellence |
| ⏱️ | Mila | Pragmatist |
| 📟 | Sven | Operations / SRE |
| 🧪 | Lea | Testing / QA |
| 🔬 | Theo | Reality Check |
| 🎭 | Ruth | Devil's Advocate |
| 🔀 | Pablo | Reframer |

## Rooms

| Id | Name | Cast |
|---|---|---|
| `round-table` (default) | Round Table | Kira, Henrik, Nadia, Jonas, Mila |
| `architecture` | Architecture Review | Henrik, Nadia, Sven, Mila, Ruth |
| `code-review` | Code Review | Nadia, Jonas, Lea, Mila |
| `release` | Go-Live Check | Sven, Lea, Nadia, Mila, Kira |
| `decision` | Decision Room | Pablo, Theo, Ruth, Mila, Kira |
| `product` | Product & Customer | Kira, Mila, Henrik, Pablo |

## Customize per project

Add `.party/personas.md` and/or `.party/rooms.md` to a project, in the same format as
`skills/party-mode/references/personas.md` and `rooms.md`. A matching code or id replaces the built-in entry
(copy it and edit — every field is required); a new one is added. Check your overrides with:

```bash
bash tests/validate.sh --party-dir /path/to/project/.party
```

## Memory and notes

- **Memory** (opt-in: `--remember` or `memory: true` on a room) lives in `.party/memory/<room>.md` — a few
  one-line entries per session so the room picks up where it left off. Delete the file to forget.
- **Notes** (offered at wrap-up) go to `.party/notes/<date>-<topic>.md`.

Whether `.party/` is committed is up to the project; add `.party/memory/` to `.gitignore` if it shouldn't be
shared.

## Development

```bash
bash tests/run-tests.sh   # validator self-tests
bash tests/validate.sh    # validate this plugin
```

Release: bump `version` in `.claude-plugin/plugin.json`, add a `CHANGELOG.md` entry, tag `vX.Y.Z`, and update the
version in `vmeyer/claude-plugins`.

## License

MIT
