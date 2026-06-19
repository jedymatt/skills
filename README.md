# jedymatt-skills

My personal [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills). This repo is the source of truth, published to GitHub as [`jedymatt/skills`](https://github.com/jedymatt/skills). Install them two ways: with the [`skills`](https://skills.sh) CLI (works across many agents, skills only), or as a Claude Code plugin (Claude Code only, can also bundle subagents and MCP servers).

## Skills

| Skill | What it does |
|-------|--------------|
| `coding-principles` | Code-quality defaults: Rule of Three, single responsibility, no boolean params, max 3 args, named constants, narrow coupling, no over-engineering (YAGNI). |
| `detecting-code-smells` | Review-time detection: scan a file/diff/PR for design smells (god functions, feature envy, primitive obsession, …) and report a findings list. Complements `coding-principles`. |
| `handoff` | Save a short, forward-looking note (per-topic, named by git branch) to `.handoff/handoff.md` so the next session can pick up. You pick which topics carry forward. Pairs with `load-handoff`. |
| `load-handoff` | Read back the handoff saved by `handoff` — "where was I?" / "catch me up". Shows all topics, or one. Read-only. |
| `stacking-prs` | Stacked PRs with Git Town: dependent branches, whole-stack sync/propose, and shipping a stack in order. Builds on `using-git-town`. |
| `using-git-town` | How to use [Git Town](https://www.git-town.com/) for branch creation, syncing, switching, proposing, and shipping. |
| `writing-plain-english` | Write simple, natural English. Short sentences, plain words, no filler. |

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
