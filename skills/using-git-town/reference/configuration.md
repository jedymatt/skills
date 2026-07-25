# Git Town Configuration Reference

> Verified against **Git Town 24.0.0**. Defaults change between majors — `git town config` prints the live, authoritative values for the current repo. Prefer it over trusting the tables below.
>
> **On v23?** Only two things here differ: secrets print by default (`--redact` hides them, rather than `--show-secrets` revealing them), and Bitbucket uses `bitbucket-app-password` instead of `bitbucket-api-token`. Every setting name, default, and the precedence order below are identical in v23 and v24. On **v22 or older** the precedence order was different — v23 introduced the ordering shown below, so check the docs for your version.

## Setup

```bash
git town init                        # interactive setup (recommended first run)
git town config                      # view current config (secrets redacted)
git town config --show-secrets       # reveal tokens
git town config remove               # remove all git-town config
git town config get-parent [branch]  # get parent of branch
```

## Configuration Precedence

Highest to lowest:

1. **CLI flags**
2. **Git metadata** — `git config git-town.<key> <value>` (local overrides global)
3. **Config file** — `git-town.toml`, `.git-town.toml`, or `.git-branches.toml`
4. **Environment variables** — `GIT_TOWN_<PREFERENCE>=<value>`
5. **System-specific settings**
6. **Defaults**

> Env vars rank *below* the config file, not above it. This was reordered in v23.

## Config File Format (git-town.toml)

The official v24 template — values shown are the defaults unless noted:

```toml
[branches]
main = ""                     # must be set by the user
contribution-regex = ""
default-type = "feature"      # type assigned to branches with no recorded type
feature-regex = ""
observed-regex = ""
perennial-regex = ""
perennials = []

[create]
branch-prefix = ""
new-branch-type = "feature"
share-new-branches = "no"     # no | push | propose  (a string, not a boolean)

[hosting]
dev-remote = "origin"
origin-hostname = ""          # use the hostname in the origin URL
forge-type = ""               # auto-detect

[propose]
breadcrumb = "none"           # none | branches | stacks
breadcrumb-direction = "down" # down | up

[ship]
delete-tracking-branch = true
strategy = "api"

[sync]
auto-sync = true
feature-strategy = "merge"
perennial-strategy = "rebase"
prototype-strategy = "rebase" # sample value; when unset it follows feature-strategy
push-hook = true
tags = true
upstream = true
```

## Sync Strategies

### Feature (`sync.feature-strategy`)

| Strategy | Behavior |
|----------|----------|
| **merge** (default) | Merge parent into feature branch. Safest option. |
| **rebase** | Rebase feature onto parent. Force-pushes with `--force-with-lease --force-if-includes`. |
| **compress** | Merge tracking + parent, then compress the branch to one commit. More conflicts in multi-user environments. |

### Perennial (`sync.perennial-strategy`)

| Strategy | Behavior |
|----------|----------|
| **rebase** (default) | Rebase local perennial branches onto their tracking branch. |
| **ff-only** | Fast-forward only; errors if a fast-forward isn't possible. |

Only these two values are accepted — `merge` is **not** valid here.

### Prototype (`sync.prototype-strategy`)

Accepts the same values as feature sync. When unset it falls back to `sync.feature-strategy` (so `merge` by default).

### Other Sync Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `sync.auto-sync` | true | Auto-sync on branch-creating commands |
| `sync.push-hook` | true | Run Git's pre-push hook when pushing |
| `sync.tags` | true | Sync tags with remote |
| `sync.upstream` | true | Sync with upstream remote |
| `sync.push-branches` | true | Push branches during sync |
| `sync.auto-resolve` | true | Auto-resolve phantom merge conflicts |
| `sync.detached` | false | Don't update the perennial root during sync (git key: `git-town.detached`) |

The last three are valid `[sync]` keys but are absent from the template `git town init` generates.

## Ship Strategies (`ship.strategy`)

| Strategy | Behavior | When to use |
|----------|----------|-------------|
| **api** (default) | Use forge API to merge (mirrors web UI button) | Standard workflow with CI checks |
| **always-merge** | `git merge --no-ff` — creates merge commit | When you want visible merge history |
| **fast-forward** | Fast-forward parent to contain branch commits | Stacked changes (avoids false conflicts) |
| **squash-merge** | Squash all commits into one | Clean single-commit history |

`ship.delete-tracking-branch` defaults to **true** — the remote branch is removed after shipping.

## Forge Integration

Set the forge with `hosting.forge-type` (auto-detected from the remote URL when empty). Valid values: `github`, `gitlab`, `gitea`, `forgejo`, `bitbucket`, `bitbucket-datacenter`, `azuredevops` (experimental).

> Named `hosting.platform` until v18.1. The old name still works — Git Town reads it and **rewrites your config to the new name**, so don't be surprised when `hosting-platform` turns into `forge-type` on disk. Several deprecated keys migrate this way.

### Connectors

GitHub and GitLab can be reached either through their API (needs a token) or through their official CLI (handles auth for you):

```toml
[hosting]
github-connector = "gh"      # api | gh
gitlab-connector = "glab"    # api | glab
```

Hardcoding a connector in the config file enforces CLI usage (or non-usage) for the whole team — prefer setting it in git metadata.

### Tokens

| Platform | Setting |
|----------|---------|
| GitHub | `github-token` (or use `gh` connector) |
| GitLab | `gitlab-token` (or use `glab` connector) |
| Gitea | `gitea-token` |
| Forgejo | `forgejo-token` |
| Bitbucket | `bitbucket-username` + `bitbucket-api-token` (**v23 and older:** `bitbucket-app-password`) |

Git stores tokens in plaintext by default; consider a credential helper backed by your OS keychain.

```bash
# WARNING: --global affects ALL repos. Ask the user for permission first.
git config --global git-town.github-token <token>
```

Or via environment variable: `export GIT_TOWN_GITHUB_TOKEN=<token>`

> Branch-type sync/push behavior: see the Branch Types table in `SKILL.md`.

## Setting Config via Git Metadata

**The git-metadata key is not always the TOML path with dashes.** Unknown keys are stored by Git and silently ignored by Git Town, so a wrong name looks exactly like success. Verified mappings:

| TOML | Git metadata key |
|------|------------------|
| `[branches] main` | `git-town.main-branch` |
| `[branches] default-type` | `git-town.unknown-branch-type` |
| `[create] new-branch-type` | `git-town.new-branch-type` (**not** `create-new-branch-type`) |
| `[create] share-new-branches` | `git-town.share-new-branches` |
| `[sync] auto-sync` | `git-town.auto-sync` (**not** `sync-auto-sync`) |
| `[sync] feature-strategy` | `git-town.sync-feature-strategy` |
| `[sync] tags` | `git-town.sync-tags` |
| `[ship] strategy` | `git-town.ship-strategy` |
| `[hosting] forge-type` | `git-town.forge-type` |
| `[propose] breadcrumb` | `git-town.proposal-breadcrumb` (**proposal-**, not `propose-`) |

```bash
# Local repo
git config git-town.sync-feature-strategy rebase
git config git-town.ship-strategy squash-merge
git config git-town.new-branch-type prototype

# Global (all repos)
# WARNING: --global affects ALL repos on this machine. MUST ask user before running.
git config --global git-town.github-token <token>
git config --global git-town.forge-type github

# Environment variable (ranks below the config file)
export GIT_TOWN_SYNC_FEATURE_STRATEGY=rebase
```

**Verify any change took effect with `git town config`** — that is the only way to tell a valid key from a typo.
