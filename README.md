# jedymatt-skills

My personal [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills). This repo is the source of truth, published to GitHub as [`jedymatt/skills`](https://github.com/jedymatt/skills). Install them two ways: with the [`skills`](https://skills.sh) CLI (works across many agents, skills only), or as a Claude Code plugin (Claude Code only, can also bundle subagents and MCP servers).

## Skills

| Skill | What it does |
|-------|--------------|
| `architecting-principles` | Module-level defaults: one-way dependencies (no cycles), depend on abstractions, code lives with its data (no `utils` dumping ground), narrow contracts, wrap external systems behind ports, one-way data flow, no over-architecting (YAGNI). One altitude above `coding-principles`. |
| `coding-principles` | Code-quality + low-cognitive-load defaults: Rule of Three, single responsibility, one level of abstraction, early return, no nested loops, no double negatives, named conditions, command–query separation, tight variable scope, one name per concept, obvious over clever, no boolean params, max 3 args, named constants, narrow coupling, no over-engineering (YAGNI). |
| `detecting-code-smells` | Review-time detection: scan a file/diff/PR for design smells (god functions, feature envy, primitive obsession, …) and report a findings list. Complements `coding-principles`. |
| `handoff` | Save a short, forward-looking note (per-topic, named by git branch) to `.handoff/handoff.md` so the next session can pick up. You pick which topics carry forward. Pairs with `load-handoff`. |
| `load-handoff` | Read back the handoff saved by `handoff` — "where was I?" / "catch me up". Shows all topics, or one. Read-only. |
| `stacking-prs` | Stacked PRs with Git Town: dependent branches, whole-stack sync/propose, and shipping a stack in order. Builds on `using-git-town`. |
| `using-git-town` | How to use [Git Town](https://www.git-town.com/) for branch creation, syncing, switching, proposing, and shipping. |
| `writing-plain-english` | Write simple, natural English. Short sentences, plain words, no filler. |

## Auto-activation

Installed as a **Claude Code plugin**, a `PreToolUse` hook reminds Claude to invoke `coding-principles` (and `architecting-principles` for structural changes) the first time it edits a **code file** in a session. It fires once per session, only for code-file extensions (not `.md`, docs, or config), and never blocks the edit. Requires [`jq`](https://jqlang.github.io/jq/).

The hook ships only with the plugin install path. With the [`skills`](https://skills.sh) CLI (or other agents), the skills' descriptions still prompt activation on their own — best-effort, since that path can't bundle hooks.

## Install with the skills CLI (any agent)

Install all skills for every project (user-level):

```bash
npx skills add jedymatt/skills -g
```

Or install into a single project only (this writes a `skills-lock.json` in that project):

```bash
npx skills add jedymatt/skills
```

The CLI pulls the skills from GitHub, not from a local clone. Add `--agent claude-code` to target Claude Code only. Run `npx skills add --help` for more flags (pick specific skills, choose agents, copy vs link).

## Install as a Claude Code plugin

This repo is also a Claude Code [plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces). The plugin bundles the same skills, and can grow to include subagents, MCP servers, slash commands, and hooks (Claude Code only).

```text
/plugin marketplace add jedymatt/skills
/plugin install jedymatt-skills@jedymatt
```

`jedymatt-skills` is the plugin name; `jedymatt` is the marketplace name. The manifests live in `.claude-plugin/` (`plugin.json` and `marketplace.json`). To add a subagent, drop a `.md` file in `agents/`; for an MCP server, add `.mcp.json` at the repo root.

## Manage

```bash
npx skills ls -g                  # list installed skills (global)
npx skills update -g              # pull the latest versions from GitHub
npx skills remove                 # remove skills (interactive)
```

## Adding a skill

1. Make a folder under `skills/` named after the skill (kebab-case).
2. Put a `SKILL.md` inside with `name` and `description` frontmatter.
3. Add longer docs under a `reference/` subfolder if needed (see `using-git-town`).
4. Commit and push to GitHub.
5. Run `npx skills update -g` to pick up the change. (Plugin users: bump `version` in `.claude-plugin/plugin.json` too, so `/plugin marketplace update` sees it.)
