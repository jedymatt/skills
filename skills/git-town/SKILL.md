---
name: git-town
description: Use when creating a new branch, creating feature branches, switching branches, managing branches with git-town, stacking changes, syncing branches, proposing PRs, shipping, or resolving git-town conflicts. Triggers on "create a branch", "new branch", "switch branch", git-town, hack, append, prepend, sync, propose, ship, compress, stacked changes.
---

# Git Town

## Overview

Git Town (v23+) is a high-level Git CLI that automates branch creation, syncing, stacking, and shipping. It maintains a branch lineage tree and handles multi-step git operations safely. Install: `brew install git-town`. Setup: `git town init`.

## When to Use

- Creating/managing feature branches, stacking PRs, syncing with parent/main
- Proposing PRs through forge, navigating branch stacks, shipping completed work
- Recovering from merge conflicts during git-town operations

**Do NOT use for:** ordinary commits on the current branch (use standard `git commit`; `git town commit` is only for committing into an ancestor branch in a stack via `--up`), worktree isolation (use `using-git-worktrees` skill), rebasing onto master in Quickli (use `quickli-rebase` skill).

## Quick Reference

| Command | Purpose | Key Flags |
|---------|---------|-----------|
| `hack <name>` | New branch off main | `-p` prototype, `--beam`, `--propose` |
| `append <name>` | Stack child branch | `-p` prototype, `--beam` |
| `prepend <name>` | Insert parent branch | `-p` prototype |
| `sync` | Update branch(es) | `-s` stack, `-a` all, `--gone`, `--prune` |
| `propose` | Create PR/MR | `-s` stack, `-t` title, `-b` body |
| `commit` | Commit into current/ancestor branch | `--up=<n>`, `-m` message |
| `ship` | Merge to parent/main | `-p`/`--to-parent`, `-m` message, `-s` strategy |
| `compress` | Squash commits | `-s` stack, `-m` message |
| `switch` | Navigate branches | `-a` all, `-t` type, `--merge`, regex filter |
| `up` / `down` | Move in stack | |
| `detach` | Remove from stack | |
| `merge` | Combine with parent | |
| `swap` | Switch pos with parent | |
| `set-parent` | Reparent branch | `--none` |
| `delete` | Remove branch | |
| `rename` | Rename + tracking + PRs | `--force` |
| `walk <cmd>` | Run cmd per stack branch | `-a` all |
| `continue` | Resume after conflict | |
| `skip` | Skip branch | `--park` |
| `undo` | Revert last command | |
| `status` | Show state | `--pending` |
| `branch` | Show hierarchy | |
| `config` | View/update config | `--redact` |

## Common Workflows

**New feature:**
```bash
git town hack my-feature           # --prototype for local-only
```

**Stacked changes:**
```bash
git town hack feature-1
# ... work, commit ...
git town append feature-2          # child of feature-1
# ... work, commit ...
git town sync --stack              # sync entire stack
git town propose --stack           # PRs for entire stack
```

**Daily sync:**
```bash
git town sync                      # current branch + ancestors
git town sync --all                # all local branches
```

**Ship (prefer forge UI, but):**
```bash
git town ship                      # ships to main (direct children only)
git town ship --to-parent          # ships into non-main parent
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
- Forgetting `--stack` on sync — only syncs current branch by default
- Trying to ship non-direct children of main — use `--to-parent` or ship ancestors first
- Using `git rebase` instead of `git town sync` — breaks lineage tracking
- Running `git branch -d` instead of `git town delete` — orphans lineage metadata

## Reference

See `reference/commands.md` for full command details and all flags.
See `reference/configuration.md` for config options, sync strategies, and forge setup.
