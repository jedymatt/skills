# Git Town Commands Reference

> For exhaustive flag details, run `git town <cmd> --help`.

---

## Basic Workflow

### hack

Create a new feature branch off the main branch. Syncs main first if workspace is clean. Transfers uncommitted changes to new branch.

```bash
git town hack <branch> [flags]
```

**Flags:** `--beam` `-b` (move commits), `--commit` `-c` (commit stash), `--detached` `-d`, `--dry-run`, `--message` `-m`, `--no-sync`, `--propose` (create + PR), `--prototype` `-p` (local-only), `--stash`/`--no-stash`, `--verbose` `-v`

```bash
git town hack my-feature              # standard feature branch
git town hack my-feature -p           # prototype (local-only, no push)
git town hack my-feature --beam       # beam current commits to new branch
git town hack my-feature --propose    # create branch + immediately open PR
```

### sync

Update local workspace with remote changes. Pulls/pushes from parent and tracking branches. Deletes branches whose remote tracking was deleted (if no unshipped changes).

```bash
git town sync [flags]
```

**Flags:** `-a`/`--all` (all branches), `-d`/`--detached`, `--dry-run`, `--gone` (clean deleted tracking), `-p`/`--prune` (empty branches), `-s`/`--stack` (entire stack), `-v`/`--verbose`, `--auto-resolve`/`--no-auto-resolve`

```bash
git town sync                         # current branch + ancestors
git town sync --stack                 # entire branch stack
git town sync --all                   # all local branches
git town sync --gone                  # clean up branches with deleted remotes
```

### switch

Navigate between branches with visual selection (VIM motions). Supports regex filtering and branch-type filtering.

```bash
git town switch [<branch-name-regex>...] [flags]
```

**Flags:** `-a`/`--all` (show local + remote), `-t`/`--type <name>` (filter by type, e.g. `observed`, combine with `+`), `-d`/`--display-types <type>`, `-m`/`--merge` (carry uncommitted changes), `-o`/`--order <asc|desc>`, `--stash`/`--no-stash`, `-v`/`--verbose`

```bash
git town switch                       # interactive branch picker
git town switch feat-                 # filter branches starting with "feat-"
git town switch --type=observed       # only observed branches
git town switch -to+c                 # observed + contribution branches (shorthand)
```

### propose

Create pull/merge request for current feature branch. Pre-populates title and description. Opens forge in browser.

```bash
git town propose [flags]
```

**Flags:** `-s`/`--stack` (propose entire stack), `-t`/`--title`, `-b`/`--body`, `--body-file`, `--dry-run`, `--verbose` `-v`

```bash
git town propose                      # PR for current branch
git town propose --stack              # PRs for entire stack
git town propose -t "Add auth" -b "Implements OAuth2 flow"
```

---

## Stacked Changes

### append

Create new feature branch as direct child of current branch. Syncs current branch first if workspace is clean.

```bash
git town append <branch> [flags]
```

**Flags:** Same as `hack` (`--beam`, `--commit`, `--detached`, `--dry-run`, `--prototype`, `--no-sync`, etc.)

```bash
git town append step-2               # child of current branch
git town append step-2 -p            # prototype child (local-only)
git town append step-2 --beam        # beam commits to new child
```

### prepend

Insert new branch between current branch and its parent. Syncs current branch first.

```bash
git town prepend <branch> [flags]
```

**Flags:** Same as `hack`/`append`.

```bash
git town prepend setup-step          # new parent of current branch
```

### commit

Commit staged changes into the current branch, or into an ancestor branch with `--up`, then sync the change down through the stack.

```bash
git town commit [flags]
```

**Flags:** `-u`/`--up <n>` (commit into the n-th ancestor: `--up=1` = parent, `--up=2` = grandparent), `--message` `-m`, `--interactive`/`--non-interactive`, `--dry-run`, `--verbose`

```bash
git town commit -m "Fix typo"               # commit to current branch
git town commit --up=1 -m "Fix typo in parent"   # commit into parent, sync children
```

### detach

Remove current branch from stack, making it an independent top-level branch that ships directly to main.

```bash
git town detach [flags]
```

**Flags:** `--dry-run`, `--verbose`

### merge

Merge current branch into its parent branch. Consolidates both branch changes. Current branch is deleted after.

```bash
git town merge [flags]
```

**Flags:** `--dry-run`, `--verbose`

### swap

Switch position of current branch with its parent in the stack. Requires all branches synced with no merge commits.

```bash
git town swap [flags]
```

**Flags:** `--dry-run`, `--verbose`

### set-parent

Move branch (and all its children) under a different parent.

```bash
git town set-parent [flags]
```

**Flags:** `--none` (remove parent, make perennial-like), `--auto-resolve`, `--verbose`

```bash
git town set-parent                  # interactive parent selection
git town set-parent --none           # make branch independent
```

### diff-parent

Show changes committed to current feature branch (diff between branch and parent).

```bash
git town diff-parent [branch] [flags]
```

**Flags:** `--name-only`, `--diff-filter`, `--verbose`

### up

Navigate up in branch stack (switch to child). If multiple children, prompts to choose.

```bash
git town up [flags]
```

**Flags:** `--merge` `-m` (carry uncommitted changes), `-d`/`--display-types <type>`, `-o`/`--order <asc|desc>`, `--verbose`

### down

Navigate down in stack (switch to parent).

```bash
git town down [flags]
```

**Flags:** `--merge` `-m` (carry uncommitted changes), `-d`/`--display-types <type>`, `-o`/`--order <asc|desc>`, `--verbose`

---

## Branch Type Commands

All branch type commands convert current or named branches. Use `feature` to revert back.

### contribute

Mark branch as contribution (sync tracking only, no parent sync). For collaborating on others' branches.

```bash
git town contribute [branches...]
```

### observe

Mark branch as observed (read-only, pulls but never pushes).

```bash
git town observe [branches...]
```

### park

Mark branch as parked (excluded from sync unless explicitly synced).

```bash
git town park [branches...]
```

### prototype

Mark branch as prototype (syncs parent but never pushes to remote).

```bash
git town prototype [branches...]
```

### feature

Revert branch back to standard feature type.

```bash
git town feature [branches...]
```

---

## Error Handling

### continue

Resume git-town operation paused due to error (e.g., merge conflict). Retries failed operation and executes remaining operations.

```bash
git town continue [flags]
```

**Flags:** `--verbose`

### skip

Skip problematic branch during operations. Useful for handling merge conflicts in batch sync.

```bash
git town skip [flags]
```

**Flags:** `--park` (also park the skipped branch), `--verbose`

```bash
git town skip                        # skip and move on
git town skip --park                 # skip and park to avoid future conflicts
```

### undo

Revert effects of last completed git-town command. Restores repository to prior state.

```bash
git town undo [flags]
```

**Flags:** `--verbose`

### status

Show if merge conflict was encountered during git-town operation. Lists available actions.

```bash
git town status [flags]
```

**Flags:** `--pending` (display only pending command name — useful for shell prompts)

### runlog

Display repository state before and after previous git-town commands.

```bash
git town runlog [flags]
```

**Flags:** `--verbose`

---

## Advanced

### ship

Merge completed feature branch into parent/main and remove it. Most people use forge UI instead — primarily useful for offline development or stacked changes.

```bash
git town ship [branch] [flags]
```

**Flags:** `-p`/`--to-parent` (ship into non-main parent), `-m`/`--message`, `-f`/`--message-file` (`-` reads STDIN), `-s`/`--strategy <name>` (override ship strategy), `--ignore-uncommitted`/`--no-ignore-uncommitted`, `--dry-run`, `--verbose`

**Ship strategies** (configured via `ship.strategy`):
- `api` (default): Use forge API to merge (mirrors web UI merge button)
- `always-merge`: Creates merge commit with `git merge --no-ff`
- `fast-forward`: Fast-forwards parent to contain branch commits
- `squash-merge`: Squashes all commits into single commit

```bash
git town ship                        # ship current branch to main
git town ship --to-parent            # ship into parent (for stacks)
git town ship feature-1 -m "Add auth module"
```

### compress

Squash all commits on branch into single commit. First commit's message is used by default.

```bash
git town compress [flags]
```

**Flags:** `-s`/`--stack` (compress all branches in stack), `-m`/`--message`, `--no-verify`, `--dry-run`, `--verbose`

```bash
git town compress                    # squash current branch
git town compress --stack            # squash all branches in stack
git town compress -m "Consolidated feature work"
```

### delete

Remove branch from local and remote. Automatically reparents child branches to deleted branch's parent.

```bash
git town delete [branches...] [flags]
```

**Flags:** `--dry-run`, `--verbose`

### rename

Rename branch and its tracking branch. Automatically updates associated PRs.

```bash
git town rename [old] <new> [flags]
```

**Flags:** `--force` (allow renaming perennial branches), `--dry-run`, `--verbose`

### walk

Run a command on each branch in the stack (or all branches). Useful for running lint/test across a stack.

```bash
git town walk <command> [flags]
```

**Flags:** `-a`/`--all` (all branches, not just stack), `-s`/`--stack`, `--verbose`

```bash
git town walk "pnpm test"            # run tests on each stack branch
git town walk --all "pnpm lint"      # lint across all branches
```

### repo

Open the forge repository page in browser.

```bash
git town repo
```

### branch

Display the branch hierarchy tree.

```bash
git town branch
```

---

## Setup

### init

Interactive setup assistant. Walks through all configuration options.

```bash
git town init
```

### config

Display or update git-town configuration.

```bash
git town config [flags]
git town config get-parent [branch]
git town config remove
```

**Flags:** `--redact` (hide tokens), `--verbose`

### offline

Toggle offline mode (development without remote access).

```bash
git town offline [yes|no]
```

### completions

Generate shell completions.

```bash
git town completions [bash|zsh|fish|powershell]
```
