# Design: `jedymatt-skills` as a Cursor plugin

**Date:** 2026-07-22
**Status:** Approved (design)

## Goal

Package the existing skill set and config as an installable **Cursor plugin**, mirroring
how this repo already works as a **Claude Code plugin**. A Cursor user should be able to
install this plugin and get the same 8 skills plus the coding-skills reminder hook.

## Context

This repo is a Claude Code plugin:

- **8 skills** in `skills/<name>/SKILL.md`: architecting-principles, coding-principles,
  detecting-code-smells, handoff, load-handoff, stacking-prs, using-git-town,
  writing-plain-english.
- **1 hook (the "config")**: `hooks/hooks.json` (Claude `PreToolUse: Edit|Write|MultiEdit`)
  runs `hooks/remind-coding-skills.sh`, which — once per session, on the first code-file
  edit — reminds the agent to invoke coding-principles (and architecting-principles for
  structural changes).
- **Manifests**: `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`.

Cursor's plugin format (verified against the official `cursor/plugins` repo) is nearly
1:1 with Claude Code's:

| Claude Code | Cursor | Portability |
|---|---|---|
| `.claude-plugin/plugin.json` | `.cursor-plugin/plugin.json` | rename + tweak fields |
| `.claude-plugin/marketplace.json` | `.cursor-plugin/marketplace.json` | near-identical |
| `skills/<name>/SKILL.md` | `skills/<name>/SKILL.md` | **same format — shared** |
| `hooks/hooks.json` (Claude schema) | `hooks/hooks.cursor.json` (Cursor schema) | **real translation** |
| `${CLAUDE_PLUGIN_ROOT}` | `${CURSOR_PLUGIN_ROOT}` | rename |

Cursor skills use the same `name` + `description` frontmatter as Anthropic skills
(confirmed via `cursor/plugins` example `review-plugin-submission/SKILL.md`).

## Decision: same repo, shared skills

Add Cursor manifests and Cursor hooks to **this** repo, and point the Cursor plugin at the
**same** `skills/` folder Claude Code uses. One source of truth for skill content — no
copies to keep in sync. Each tool reads its own manifest from the repo root.

Rejected alternatives:
- **Separate Cursor repo** — duplicates skill content, drift risk.
- **Restructure to multi-plugin monorepo** — disruptive to the working Claude Code plugin.

## Target layout

```
jedymatt/skills
├── .claude-plugin/                     # unchanged (Claude Code)
│   ├── plugin.json
│   └── marketplace.json
├── .cursor-plugin/                     # NEW (Cursor)
│   ├── plugin.json
│   └── marketplace.json
├── skills/                             # SHARED — both tools read these
│   └── <8 skills>/SKILL.md             #   (no changes, no copies)
└── hooks/
    ├── hooks.json                      # unchanged (Claude schema)
    ├── remind-coding-skills.sh         # unchanged (Claude)
    ├── hooks.cursor.json               # NEW (Cursor schema)
    └── remind-coding-skills.cursor.sh  # NEW (Cursor)
```

## Components

### Skills — shared, zero duplication
No skill content changes. Cursor's `plugin.json` sets `"skills": "./skills/"`, the same
folder Claude reads. All 8 skills carry over unchanged.

### Hook — the only real translation
Two conflicts drive the design:

1. **Path collision.** Both tools want `hooks/hooks.json`. Claude auto-discovers that path;
   Cursor's path is declared in its `plugin.json` `"hooks"` field. Fix: Cursor uses
   `hooks/hooks.cursor.json`, leaving Claude's `hooks/hooks.json` untouched.

2. **Injection point differs.** Claude fires on `PreToolUse: Edit|Write` and injects via
   `additionalContext`. In Cursor, `preToolUse` output only supports `permission`/`deny`
   (its `agent_message` reaches the agent *only when the edit is blocked*), so it cannot
   inject a non-blocking reminder. The event whose output supports context injection is
   **`sessionStart`**, via its `additional_context` output field ("added to the
   conversation's initial system context").

**Mapping:** use **`sessionStart`** to inject the same reminder once at session start via
`additional_context`. Rationale: guaranteed to fire exactly once per session, non-blocking
by nature, fires in the Cursor CLI, and needs no tool-name matcher or dedup marker.
Trade-off: it loses the "only on a code file" filter (session start is not tied to a file),
which is acceptable — the reminder text is already conditional ("if you are about to create
or modify code…").

`hooks/remind-coding-skills.cursor.sh` is a small rewrite of the Claude script: it drains
stdin (the `sessionStart` payload is not needed), then emits `{"additional_context": "…"}`
with the same reminder text. No `jq` dependency (the payload is static). Fail-open: it can
only ever print the reminder or nothing, never blocks. The hook is wired via
`hooks/hooks.cursor.json` using `${CURSOR_PLUGIN_ROOT}`.

### Manifests
- `.cursor-plugin/plugin.json`: kebab-case `name` (`jedymatt-skills`), `version`,
  `description`, `author`, `license`, `homepage`/`repository`, `keywords`,
  `"skills": "./skills/"`, `"hooks": "./hooks/hooks.cursor.json"`.
- `.cursor-plugin/marketplace.json`: `name`, `owner`, one plugin entry with `source: "."`.

## Out of scope (YAGNI)
No rules (`.mdc`), subagents, MCP servers, or commands. The repo has none, and skills cover
the need. Just skills + the one hook.

## Open items (verify during implementation, not blocking)
- Whether the `sessionStart` hook fires identically in Cursor CLI vs editor (schema
  confirmed; runtime behavior to confirm on install).
- Whether a single-plugin-at-root `source: "."` is accepted, or Cursor prefers a plugin
  subdirectory.

## Success criteria
- `.cursor-plugin/plugin.json` and `marketplace.json` exist and parse as valid JSON.
- All 8 skills are discoverable by Cursor from the shared `skills/` folder.
- The Cursor hook injects the coding-skills reminder once per session without blocking.
- The existing Claude Code plugin is unchanged and still works.
