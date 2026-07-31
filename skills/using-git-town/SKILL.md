---
name: using-git-town
description: Use when creating a feature branch, switching branches, syncing a branch with its parent or main, proposing a PR, or shipping completed work with git-town. Also for recovering from conflicts during git-town operations. Triggers on "create a branch", "new branch", "switch branch", git-town, hack, sync, propose, ship. For stacked/dependent branches, see stacking-prs.
---

# Git Town

## Overview

Git Town is a high-level Git CLI that automates branch creation, syncing, and shipping, and tracks a branch lineage tree. Install: `brew install git-town`. Setup: `git town init`.

Commands below are for **v24**. If the repo is on v23, see [Version Differences](#version-differences) — five things changed.

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
| `status` | Show state | `--pending`, `reset`, `show` |
| `branch` | Show hierarchy | |
| `config` | View config | `--show-secrets` (v23: `--redact`) |

Stacking commands (`append`, `prepend`, `commit --up`, `sync --stack`, `propose --stack`, `ship --to-parent`, `up`/`down`, `swap`, `detach`, `combine`, `diff-parent`, `set-parent`, `walk`) are in **stacking-prs**.

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

**On v22 or older?** `up` and `down` are *reversed* from what **stacking-prs** documents — v23 swapped them so `up` goes to the parent. Config precedence also differed: v23 introduced the order in `reference/configuration.md`.

## Reference

See `reference/commands.md` for command details and all flags.
See `reference/configuration.md` for config options, sync strategies, and forge setup.
Stacking commands live in the **stacking-prs** skill.
