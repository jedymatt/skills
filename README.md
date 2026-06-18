# jedymatt-skills

My personal [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills). The repo is the source of truth. Install links each skill into your Claude skills folder, so editing a skill here updates it live.

## Skills

| Skill | What it does |
|-------|--------------|
| `coding-principles` | Code-quality defaults: Rule of Three, single responsibility, no boolean params, max 3 args, named constants, narrow coupling. |
| `git-town` | How to use [Git Town](https://www.git-town.com/) for branches, stacks, syncing, and shipping. |
| `writing-plain-english` | Write simple, natural English. Short sentences, plain words, no filler. |

## Install

```bash
./skills.sh install
```

This symlinks every skill in `skills/` into `~/.claude/skills/`. If a real folder with the same name is already there, the script moves it aside to a `.bak.<timestamp>` copy first, so nothing is lost. Re-running is safe.

## Commands

```bash
./skills.sh install     # link all skills into the Claude skills dir
./skills.sh list        # show each skill and whether it is linked
./skills.sh uninstall   # remove only the links this script made
./skills.sh help        # show usage
```

To install somewhere else, set `CLAUDE_SKILLS_DIR`:

```bash
CLAUDE_SKILLS_DIR=/path/to/skills ./skills.sh install
```

## Adding a skill

1. Make a folder under `skills/` named after the skill (kebab-case).
2. Put a `SKILL.md` inside with `name` and `description` frontmatter.
3. Add longer docs under a `reference/` subfolder if needed (see `git-town`).
4. Run `./skills.sh install`.
