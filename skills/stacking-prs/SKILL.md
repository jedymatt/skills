---
name: stacking-prs
description: Use when building or managing stacked PRs / dependent branches with Git Town — creating child or parent branches, committing into an ancestor, syncing or proposing a whole stack, shipping a stack in order, or reordering/detaching branches. Triggers on "stacked changes", "PR stack", "stack of branches", "append branch", "prepend branch", "sync --stack", "propose --stack", "ship the stack".
---

# PR Stacking (with Git Town)

## Overview

A stack is a chain of dependent branches — each the child of the one before — so a large change ships as a series of small, reviewable PRs instead of one big one. Git Town tracks the parent→child lineage and keeps the chain in sync.

**REQUIRED BACKGROUND:** the **using-git-town** skill. Install/init, branch types, config, and error recovery (`continue`/`skip`/`undo`) all apply here and are not repeated.

## When to Use

- A change too big for one PR — split it into dependent steps.
- Work that builds on a branch still in review.

**Not for:** independent branches (use `git town hack`), or ordinary commits on the current branch.

## The Stack Model

- Each branch has one parent; `main` is the root.
- Children sync *from* their parent; review and ship **bottom-up** (parent before child).
- `git town branch` shows the lineage tree.

## Commands

| Command | Purpose |
|---|---|
| `append <name>` | New branch as a child of the current one |
| `prepend <name>` | Insert a new branch between current and its parent |
| `commit --up=<n>` | Commit into the n-th ancestor (`1` = parent), then sync down |
| `sync --stack` | Sync every branch in the stack |
| `propose --stack` | Open a PR for each branch in the stack |
| `ship` / `ship --to-parent` | Ship the bottom branch to main / ship into a non-main parent |
| `up` / `down` | Move to a child / to the parent |
| `swap` | Swap the current branch's position with its parent |
| `detach` | Pop the current branch out of the stack (it then ships to main) |
| `set-parent` | Reparent a branch (and its children); `--none` makes it independent |
| `merge` | Merge the current branch into its parent, then delete it |
| `walk <cmd>` | Run a command on each branch in the stack |

Full flags: `git town <cmd> --help`.

## Workflow

```bash
git town hack feature-1            # base of the stack (off main)
# work, commit
git town append feature-2          # child of feature-1
# work, commit
git town sync --stack              # sync the whole stack
git town propose --stack           # one PR per branch
```

Fix something lower in the stack without leaving your branch:

```bash
git town commit --up=1 -m "Fix in parent"   # commit into parent, then sync children down
```

## Shipping a Stack

- Ship **bottom-up**: the parent must merge before its child.
- `git town ship` ships a direct child of main; for deeper branches use `git town ship --to-parent`, or ship the ancestors first.
- After each ship, run `git town sync --stack` to reparent and clean up.

## Common Mistakes

- **Forgetting `--stack`** on `sync`/`propose` — without it they only touch the current branch.
- **Shipping out of order** — shipping a child before its parent. Ship the bottom first, or use `--to-parent`.
- **`git rebase` instead of `git town sync`** — breaks lineage tracking.
- **`git branch -d` instead of `git town delete`** — orphans the lineage metadata.
- **Stacks too deep** — long chains are painful to review and rebase. Keep them short.
