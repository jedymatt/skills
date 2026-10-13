---
name: using-git-town
description: Use when creating a feature branch, switching branches, syncing a branch with its parent or main, proposing a PR, or shipping completed work with git-town, including stacks of dependent branches (append, prepend, sync --stack, propose --stack, ship --to-parent). Also for recovering from conflicts during git-town operations. Triggers on "create a branch", "new branch", "switch branch", git-town, hack, sync, propose, ship, append. How stacks work in general, whatever the tool, is stacking-prs.
---

# Git Town

## Overview

Git Town is a high-level Git CLI that automates branch creation, syncing, and shipping, and tracks a branch lineage tree. Install: `brew install git-town`. Setup: `git town init`.

Commands below are for **v24**. If the repo is on v23, see [Version Differences](#version-differences) — five things changed.

**Stacking PRs?** The Git Town commands are in [Stacks](#stacks) below. How stacks work in general (when to stack, merge order, squash merges) is the **stacking-prs** skill.

## When to Use

- Creating and syncing feature branches; switching between branches.
- Proposing a PR and shipping completed work through the forge.
- Recovering from merge conflicts during git-town operations.

**Do NOT use for:** ordinary commits on the current branch (use standard `git commit`), or worktree isolation (use `using-git-worktrees`).

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
| `status` | Show state | `--pending`, `reset`, `show` |
| `branch` | Show hierarchy | |
| `config` | View config | `--show-secrets` (v23: `--redact`) |

Stacking commands are in [Stacks](#stacks).

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

## Stacks

Each branch has one parent, and `main` is the root. Children sync *from* their parent, and branches ship bottom-up. `git town branch` shows the tree.

| Command | Purpose |
|---|---|
| `append <name>` | New branch as a child of the current one |
| `prepend <name>` | Insert a new branch between the current one and its parent |
| `commit --up=<n>` | Commit **staged** changes into the n-th ancestor (`1` = parent), then sync them back down |
| `sync --stack` | Sync every branch in the stack |
| `propose --stack` | Open a PR for each branch in the stack |
| `ship` / `ship --to-parent` | Ship the bottom branch to main / ship into a non-perennial parent |
| `up` / `down` | `up` → **parent** (toward main); `down` → **child** (toward the tip) |
| `swap` | Swap the current branch's position with its parent |
| `detach` | Pop the current branch out of the stack (it then ships to main) |
| `set-parent` | Reparent a branch (and its children); `--none` makes it **perennial** |
| `combine` | Fold the current branch into its parent (**v23: `merge`**) |
| `diff-parent [<branch>]` | Show what a branch adds on top of its parent |
| `walk --stack <cmd>` | Run a command on each branch in the stack (`--all` = every local feature branch) |

```bash
git town hack feature-1            # base of the stack (off main)
git town append feature-2          # child of feature-1
git town sync --stack              # sync the whole stack
git town propose --stack           # one PR per branch

git add -p
git town commit --up=1 -m "Fix in parent"   # fix the parent without leaving this branch
```

**Ship a stack:** `git town ship` ships a direct child of main. For a deeper branch, ship its ancestors first or use `ship --to-parent`. Run `git town sync --stack` after each ship to reparent and clean up.

**Breadcrumbs:** a map of the stack in each PR description. It's off by default.

```toml
[propose]
breadcrumb = "stacks"          # none (default) | branches | stacks
breadcrumb-direction = "down"  # down (default) | up
```

In git config the key is `git-town.proposal-breadcrumb`: **proposal-**, not `propose-`. The wrong name is accepted silently and does nothing.

**Stack mistakes:**
- Forgetting `--stack` on `sync` or `propose`. Without it they only touch the current branch.
- Getting `up`/`down` backwards. v23 swapped them, and both succeed silently on the wrong branch, so check with `git town branch`.
- `set-parent --none` to "detach". That makes the branch perennial (never shipped). Use `detach`.

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
- **Abort but keep the work done so far:** `git town status reset`
- **Check state:** `git town status` (`--pending` for shell prompts, `show` for full detail)
- **View history:** `git town runlog`

**Phantom conflicts** — conflicts caused by changes already present in an ancestor — are auto-resolved by default on `hack`, `append`, `prepend`, `sync`, `propose`, `set-parent`, and `swap`. Pass `--no-auto-resolve` to handle them yourself. (`ship` has no such flag.)

## Common Mistakes

- **MUST ask the user before running any `git config --global` command** — global config affects ALL repositories on the machine, not just the current one
- Using `git rebase` instead of `git town sync` — breaks lineage tracking
- Running `git branch -d` instead of `git town delete` — orphans lineage metadata

## Version Differences

This skill documents **v24**. Check with `git town --version` before relying on the items below — they are the only things that differ between v23 and v24. Everything else in this skill applies to both.

| Task | v23 | v24 |
|------|-----|-----|
| Fold a branch into its parent | `git town merge` | `git town combine` |
| Show secrets in config output | shown by default; `--redact` hides them | redacted by default; `--show-secrets` reveals them |
| `ship` commit message (api strategy) | opens an editor | uses the forge's own message; `--enter-message` restores the editor |
| `ship -m "..."` | whole string is the message | first line = subject, rest = body (like `git commit -m`) |
| Bitbucket auth | `bitbucket-app-password` | `bitbucket-api-token` (app passwords no longer work) |

**On v22 or older?** `up` and `down` are *reversed* from what [Stacks](#stacks) documents — v23 swapped them so `up` goes to the parent. Config precedence also differed: v23 introduced the order in `reference/configuration.md`.

## Reference

See `reference/commands.md` for command details and all flags.
See `reference/configuration.md` for config options, sync strategies, and forge setup.
