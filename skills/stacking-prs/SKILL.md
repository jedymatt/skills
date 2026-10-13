---
name: stacking-prs
description: Use when building or managing stacked PRs / dependent branches with any tool (gh stack, Git Town, or plain git and gh) — starting a branch on top of one still in review, deciding between a stack and separate PRs, restacking after a lower branch changes, getting the rest of a stack onto main after the bottom PR merges, or opening and merging a stack in order. Triggers on "stacked changes", "PR stack", "stack of branches", "dependent PRs", "restack", "merge the stack". Where to cut an existing PR is splitting-prs.
---

# Stacking PRs

## Overview

A stack is a chain of branches where each PR's base is the branch below it, so a reviewer sees one layer's diff at a time. The bottom merges first. The ideas are the same in every tool; only the commands differ.

## Stack or separate PRs

Stack a branch only when it needs code from the one below. Independent work goes in sibling PRs off the base: a stack makes every PR wait for the ones under it. Keep stacks short, since each layer is another rebase when something below changes.

## Pick the tool

Use what the repo already uses, checked in this order:

1. `gh stack` (`gh extension list`): the **gh-stack** skill.
2. Git Town (`git town --version`, or `git-town.*` keys in git config): the Stacks section of **using-git-town**.
3. Otherwise, plain git and `gh`.

Don't track one stack with two tools. Each keeps its own parent records, and they drift apart.

## Operations

| Do | Plain git + gh | Git Town | gh stack |
|---|---|---|---|
| New branch on top of `A` | `git switch -c B A` | `git town append B` | `gh stack add B` |
| Open the PRs | `gh pr create --base <parent>` per branch | `git town propose --stack` | `gh stack submit --auto` |
| Restack after `A` changes | On the top branch: `git rebase --update-refs A` | `git town sync --stack` | `gh stack rebase --upstack` |
| Bottom PR merged | `git rebase --update-refs --onto main <old A tip> <top>` | `git town sync --stack` | `gh stack sync` |
| Merge | Bottom first, then the step above | `git town ship`, bottom first | `gh stack merge <pr> --yes` |

Push rewritten branches with `git push --force-with-lease`, never plain `--force`.

## Merge bottom-up

- **Squash merges leave the old commits in the child.** A plain `git rebase main` replays them and conflicts. Rebase `--onto` from the old parent tip; gh stack and Git Town do this for you.
- **A PR merges into the base it shows.** Clicking merge on a child whose base is still its parent branch lands it in that branch, not `main`. Check `gh pr view <n> --json baseRefName`, and fix it with `gh pr edit <n> --base main`.
- **Deleting a base branch by hand closes the PRs on it.** GitHub only retargets them when its own delete-after-merge removes the branch.

## Fixes lower in the stack

Put a fix in the layer that owns the change, then restack everything above it, even for a small cleanup. A fix patched into a higher layer leaves the lower PR wrong.

## PR bodies

Each PR lists the whole stack, bottom to top, marks itself, and says what it relies on below.
