# Git Town Configuration Reference

## Setup

```bash
git town init                        # interactive setup (recommended first run)
git town config                      # view current config
git town config --redact             # hide tokens in output
git town config remove               # remove all git-town config
git town config get-parent [branch]  # get parent of branch
```

## Configuration Precedence

1. **Environment variables** — highest (`GIT_TOWN_<PREFERENCE>=<value>`)
2. **Local repo git metadata** — `git config git-town.<pref> <value>`
3. **Global user git metadata** — `git config --global git-town.<pref> <value>`
4. **Config file** — lowest (`git-town.toml`, `.git-town.toml`, or `.git-branches.toml`)

## Config File Format (git-town.toml)

```toml
[branches]
main = "main"
perennials = ["staging", "production"]
perennial-regex = "release-.*"
contribution-regex = ""
observed-regex = ""
feature-regex = ""

[create]
new-branch-type = "feature"          # feature | prototype
share-new-branches = false
# branch-prefix = "user/"            # prefix for new branch names

[hosting]
platform = "github"                  # github | gitlab | gitea | forgejo | bitbucket
# origin-hostname = "github.com"     # custom hostname for SSH
# dev-remote = "origin"

[ship]
strategy = "api"                     # api | always-merge | fast-forward | squash-merge
delete-tracking-branch = false

[sync]
feature-strategy = "merge"           # merge | rebase | compress
perennial-strategy = "ff-only"       # ff-only | merge | rebase
prototype-strategy = "rebase"        # merge | rebase | compress
push-branches = true
tags = false
upstream = false
auto = true
run-detached = false
```

## Branch Configuration

| Setting | Type | Description |
|---------|------|-------------|
| `branches.main` | string | Main development branch (default: "main") |
| `branches.perennials` | list | Long-lived branches (staging, prod, etc.) |
| `branches.perennial-regex` | regex | Auto-classify perennial branches |
| `branches.contribution-regex` | regex | Auto-classify contribution branches |
| `branches.observed-regex` | regex | Auto-classify observed branches |
| `branches.feature-regex` | regex | Auto-classify feature branches |

## Create Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `create.new-branch-type` | feature | Default type for hack/append/prepend |
| `create.share-new-branches` | false | Push new branches immediately |
| `create.branch-prefix` | (none) | Prefix for new branch names |

## Sync Strategies

### Feature Sync (sync.feature-strategy)

| Strategy | Behavior |
|----------|----------|
| **merge** (default) | Merge parent into feature branch. Safest option. |
| **rebase** | Rebase feature onto parent. Force-pushes with `--force-with-lease --force-if-includes`. |
| **compress** | Merge + compress into single commit. More merge conflicts in multi-user environments. |

### Perennial Sync (sync.perennial-strategy)

| Strategy | Behavior |
|----------|----------|
| **ff-only** (default) | Fast-forward only |
| **merge** | Allow merge commits |
| **rebase** | Rebase onto origin |

### Prototype Sync (sync.prototype-strategy)

Same options as feature sync. Default: **rebase**.

### Other Sync Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `sync.push-branches` | true | Push after sync |
| `sync.tags` | false | Sync tags with remote |
| `sync.upstream` | false | Sync with upstream remote |
| `sync.auto` | true | Auto-sync on branch create commands |
| `sync.run-detached` | false | Don't update perennial root during sync |

## Ship Strategies (ship.strategy)

| Strategy | Behavior | When to use |
|----------|----------|-------------|
| **api** (default) | Use forge API to merge (mirrors web UI button) | Standard workflow with CI checks |
| **always-merge** | `git merge --no-ff` — creates merge commit | When you want visible merge history |
| **fast-forward** | Fast-forward parent to contain branch commits | Stacked changes (avoids false conflicts) |
| **squash-merge** | Squash all commits into one | Clean single-commit history |

**Other ship settings:**

| Setting | Default | Description |
|---------|---------|-------------|
| `ship.delete-tracking-branch` | false | Delete remote branch after ship |

## Forge Integration

| Platform | Token Setting | Notes |
|----------|---------------|-------|
| GitHub | `github.token` | Or use GitHub CLI (`gh auth`) |
| GitLab | `gitlab.token` | Personal access token |
| Gitea | `gitea.token` | Personal access token |
| Forgejo | `forgejo.token` | Personal access token |
| Bitbucket | `bitbucket.username` + `bitbucket.app-password` | App password required |

Set platform: `hosting.platform = "github"` (or auto-detected from remote URL).

Set token via git config (**ask the user before running global config commands**):
```bash
# WARNING: --global affects ALL repos. Ask the user for permission first.
git config --global git-town.github-token <token>
```

Or environment variable:
```bash
export GIT_TOWN_GITHUB_TOKEN=<token>
```

## Branch Type Sync Behavior

| Type | Syncs from parent | Pushes to remote | Auto-removes when tracking deleted |
|------|-------------------|------------------|------------------------------------|
| Feature | Yes | Yes | Yes (if no unshipped changes) |
| Contribution | No | Yes | Yes |
| Observed | No | No (read-only) | Yes |
| Parked | No (unless explicit) | No (unless explicit) | No |
| Prototype | Yes | No | No |
| Perennial | Yes (from origin) | Yes | No |

## Setting Config via Git

```bash
# Local repo
git config git-town.sync-feature-strategy rebase
git config git-town.ship-strategy squash-merge
git config git-town.create-new-branch-type prototype

# Global (all repos)
# WARNING: --global affects ALL repos on this machine. MUST ask user before running.
git config --global git-town.github-token <token>
git config --global git-town.hosting-platform github

# Environment variable (highest precedence)
export GIT_TOWN_SYNC_FEATURE_STRATEGY=rebase
```
