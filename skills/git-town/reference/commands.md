# Git Town Commands Reference

> Purpose and examples per command. For the full flag list, run `git town <cmd> --help`. The most-used flags are in the skill's Quick Reference table.

---

## Basic Workflow

### hack
New feature branch off main. Syncs main first if the workspace is clean; carries uncommitted changes over.
```bash
git town hack my-feature              # standard feature branch
git town hack my-feature -p           # prototype (local-only, no push)
git town hack my-feature --beam       # move current commits to the new branch
git town hack my-feature --propose    # create branch + open PR
```

### sync
Update the workspace with remote changes. Pulls/pushes parent and tracking branches. Deletes branches whose remote tracking is gone (if no unshipped changes).
```bash
git town sync                         # current branch + ancestors
git town sync --stack                 # entire stack
git town sync --all                   # all local branches
git town sync --gone                  # clean up branches with deleted remotes
```

### switch
Navigate branches with a visual picker (VIM motions). Supports regex and branch-type filters.
```bash
git town switch                       # interactive picker
git town switch feat-                 # filter by name regex
git town switch --type=observed       # only observed branches
git town switch -to+c                 # observed + contribution (shorthand)
```

### propose
Open a PR/MR for the current branch. Pre-fills title/body and opens the forge in a browser.
```bash
git town propose                      # PR for current branch
git town propose --stack              # PRs for the whole stack
git town propose -t "Add auth" -b "Implements OAuth2"
```

---

> Stacking commands — `append`, `prepend`, `commit --up`, `swap`, `detach`, `set-parent`, `up`/`down`, `walk` — are in the **pr-stacking** skill.

## Branch Type Commands

Each converts the current or named branches. Use `feature` to revert. (Sync/push behavior per type: see the skill's Branch Types table.)

- `contribute` — sync tracking only, no parent sync (for collaborating on someone else's branch).
- `observe` — read-only: pulls but never pushes.
- `park` — excluded from sync unless synced explicitly.
- `prototype` — syncs parent but never pushes.
- `feature` — back to a standard feature branch.

```bash
git town observe their-branch
git town park wip-experiment
```

---

## Error Handling

- `continue` — resume after a paused operation (e.g. merge conflict); retries and runs the rest.
- `skip` — skip a problematic branch in a batch op; `--park` also parks it.
- `undo` — revert the last completed git-town command.
- `status` — show whether an operation is mid-conflict; `--pending` prints only the pending command (for shell prompts).
- `runlog` — show repo state before/after recent git-town commands.

```bash
git town continue                    # after resolving conflicts
git town skip --park                 # skip and park to avoid future conflicts
git town undo
```

---

## Advanced

### ship
Merge a completed branch into its parent/main and remove it. Most people use the forge UI instead; `ship` is mainly for offline work or stacks. Strategies are set via `ship.strategy` — see `reference/configuration.md`.
```bash
git town ship                        # ship current branch to main
git town ship --to-parent            # ship into a non-main parent (stacks)
git town ship feature-1 -m "Add auth module"
```

### compress
Squash all commits on a branch into one (first commit's message by default).
```bash
git town compress                    # current branch
git town compress --stack            # every branch in the stack
```

### delete
Remove a branch locally and remotely; child branches are reparented to its parent.

### rename
Rename a branch and its tracking branch; updates associated PRs. `--force` for perennial branches.

### repo
Open the forge repository page in the browser.

### branch
Show the branch hierarchy tree.

---

## Setup

- `git town init` — interactive setup assistant (run on first use).
- `git town config` — view config; `--redact` hides tokens; `config remove` clears it; `config get-parent [branch]`.
- `git town offline [yes|no]` — toggle offline mode.
- `git town completions [bash|zsh|fish|powershell]` — shell completions.
