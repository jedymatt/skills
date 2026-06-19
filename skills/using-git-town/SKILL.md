---
name: using-git-town
description: Use when creating a feature branch, switching branches, syncing a branch with its parent or main, proposing a PR, or shipping completed work with git-town. Also for recovering from conflicts during git-town operations. Triggers on "create a branch", "new branch", "switch branch", git-town, hack, sync, propose, ship. For stacked/dependent branches, see stacking-prs.
---

# Git Town

## Overview

Git Town (v23+) is a high-level Git CLI that automates branch creation, syncing, and shipping, and tracks a branch lineage tree. Install: `brew install git-town`. Setup: `git town init`.

**Stacking PRs (dependent branches)?** Use the **stacking-prs** skill — `append`, `prepend`, whole-stack sync/propose, and stack shipping live there.

## When to Use

- Creating and syncing feature branches; switching between branches.
- Proposing a PR and shipping completed work through the forge.
- Recovering from merge conflicts during git-town operations.

**Do NOT use for:** ordinary commits on the current branch (use standard `git commit`), worktree isolation (use `using-git-worktrees`), rebasing onto master in Quickli (use `quickli-rebase`). For stacked/dependent branches, use **stacking-prs**.

## Quick Reference

| Command | Purpose | Key Flags |
|---------|---------|-----------|
| `hack <name>` | New branch off main | `-p` prototype, `--beam`, `--propose` |
| `sync` | Update branch + ancestors | `-a` all, `--gone`, `--prune` |
| `switch` | Navigate branches | `-a` all, `-t` type, `--merge`, regex |
| `propose` | Create PR/MR | `-t` title, `-b` body |
| `ship` | Merge to main | `-m` message, `-s` strategy |
| `compress` | Squash commits | `-m` message |
| `delete` | Remove branch | |
| `rename` | Rename + tracking + PRs | `--force` |
| `continue` | Resume after conflict | |
| `skip` | Skip branch | `--park` |
| `undo` | Revert last command | |
| `status` | Show state | `--pending` |
| `branch` | Show hierarchy | |
| `config` | View/update config | `--redact` |

Stacking commands (`append`, `prepend`, `commit --up`, `sync --stack`, `propose --stack`, `ship --to-parent`, `up`/`down`, `swap`, `detach`, `set-parent`, `walk`) are in **stacking-prs**.

## Common Workflows

**New feature:**
```bash
git town hack my-feature           # --prototype for local-only
```

**Daily sync:**
```bash
git town sync                      # current branch + ancestors
git town sync --all                # all local branches
```

**Ship (prefer forge UI, but):**
```bash
git town ship                      # ships current branch to main
```

## Branch Types

| Type | Set via | Syncs parent | Pushes | Auto-removes |
|------|---------|-------------|--------|--------------|
| feature | `feature` | Yes | Yes | Yes |
| prototype | `prototype` / `hack -p` | Yes | No | No |
| contribution | `contribute` | No | Yes | Yes |
| observed | `observe` | No | No | Yes |
| parked | `park` | No | No | No |
| perennial | config | Yes (origin) | Yes | No |

## Error Recovery

- **Conflict during sync/ship:** resolve conflicts, then `git town continue`
- **Skip problematic branch:** `git town skip` (add `--park` to also park it)
- **Undo last command:** `git town undo`
- **Check state:** `git town status` (`--pending` for shell prompts)
- **View history:** `git town runlog`

## Common Mistakes

- **MUST ask the user before running any `git config --global` command** — global config affects ALL repositories on the machine, not just the current one
- Using `git rebase` instead of `git town sync` — breaks lineage tracking
- Running `git branch -d` instead of `git town delete` — orphans lineage metadata

## Reference

See `reference/commands.md` for command details and all flags.
See `reference/configuration.md` for config options, sync strategies, and forge setup.
Stacking commands live in the **stacking-prs** skill.
