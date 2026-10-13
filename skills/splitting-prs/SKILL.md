---
name: splitting-prs
description: Use when asked to split, break up, or shrink an existing PR or branch into smaller PRs or a stack — "too big to review", "split this into a stack", "pull the refactor into a pre-PR", "move this to a post-PR", atomic vs behavioural changes — before creating any branches, whether the repo uses gh stack, Git Town, or plain git.
---

# Splitting PRs

## Overview

Cut a PR by **kind of change**, not by commit, file type, or architecture layer. Each change is structural, behavioural, or able to land later. What depends on what sets the order.

## 1. Before and after

Read `git diff <base>...<branch>`, not the commit list; commits rarely match a PR's parts. For each change, note what was true before and after. Confirm a "move" with `git diff --color-moved=zebra`.

## 2. Label every change

| Label | What counts | Where it goes |
|---|---|---|
| **Structural** | Move, rename, extract or unify existing code. Existing tests pass with no edits. | Below the behaviour that needs it (pre-PR) |
| **Behavioural** | Anything a user or caller notices, including a change to what an existing flow outputs | Its own layer. A change to an existing flow is a separate PR from new code. |
| **Can land later** | Guard or drift tests, cleanup, fixes the feature works without | Above the feature (post-PR) |
| **Unrelated** | Serves a different goal | Its own PR off the base, outside the stack |
| **Churn** | A reworded comment or reformatting that this PR doesn't need | Drop it, or ask |

A layer carries one label. A new test is never structural, because it adds a rule that can fail. If an existing test had to change, the layer is behavioural. A fix that stops wrong or lost data in the feature is a blocker. It stays with the feature, not in a post-PR.

## 3. Pick the shape

- **New code goes in with its first caller.** A layer of helpers, types, or scaffolding that nothing calls yet only moves lines between PRs. A reviewer can't judge it without the caller. A subsystem that later PRs call through one entry point, such as an engine or a client with its own tests, can sit below its caller.
- **Stack only on a real dependency.** Independent changes become sibling PRs off the base, not a chain.
- **Any order the dependencies allow**: structural → behaviour → later, behaviour → structural → behaviour, and so on.

## 4. Present, then wait

The plan has these parts, in order:

1. A table, bottom to top: `#`, label, one sentence on what changes and for whom, files, size.
2. **Left out:** unrelated and churn changes, and where each one goes.
3. **Blockers**, and the layer each one rides with.
4. Questions, with your lean wherever two shapes are close.

Stop until the user picks. Don't create branches before that.

## 5. Build

Use what's installed: `gh stack` (**gh-stack**), then Git Town (**stacking-prs**), then plain branches with `gh pr create --base <parent>`. Build each layer from the PR's final state, not by replaying commits: `git diff <base>...<branch> -- <paths> | git apply --3way`. Copying whole files with `git checkout <branch> -- <path>` silently reverts whatever landed on the base since.

## 6. Verify

- Run typecheck and the tests of every package each layer touches, on that layer, not only at the top.
- In a structural layer, the existing tests pass with no edits.
- `git diff <original-branch> <top>` shows only what you dropped or moved out on purpose.

Push and open PRs only after the user says go.

## Common mistakes

- **Splitting by architecture** (engine → API → UI) while the refactors stay inside the feature PR.
- **A "refactor" layer that adds a test or changes an output.** Relabel it, and move the test up.
