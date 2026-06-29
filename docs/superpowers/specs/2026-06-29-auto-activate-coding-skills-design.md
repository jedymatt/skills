# Auto-activate coding skills when writing code

**Issue:** [#3 — auto activate coding related skills when starting to write a code](https://github.com/jedymatt/skills/issues/3)
**Date:** 2026-06-29
**Status:** Approved design

## Problem

Coding-related skills (`coding-principles`, `architecting-principles`) activate only
when the model decides their `description` is relevant. That activation is best-effort,
so the model sometimes starts editing code without applying them. The goal is to make
these skills fire reliably the moment code work begins.

## Goal

When Claude is about to write or modify a code file, it should be reminded to invoke the
coding skills — automatically, without the user asking.

## Approach

Two complementary mechanisms so every install path gets coverage:

| Install path | Mechanism | Guarantee |
|---|---|---|
| Claude Code **plugin** | `PreToolUse` hook that injects a reminder | Reliable, deterministic |
| `skills` CLI / other agents | Sharpened skill **descriptions** | Best-effort (model-driven) |

The hook is the reliable path but reaches only the plugin install. Description
sharpening is the only mechanism that travels with the cross-agent skills format, so it
covers everyone else as a fallback.

## Decisions

These were settled during brainstorming and are fixed for implementation:

- **Trigger:** `PreToolUse` hook matching `Edit|Write|MultiEdit` — fires the moment
  Claude is about to touch a file.
- **Action:** inject a reminder via `additionalContext` telling Claude to invoke the
  skills. Skills stay the single source of truth; the hook never duplicates their
  content.
- **Frequency:** once per session. The first qualifying code edit injects the reminder;
  the rest of the session stays silent.
- **File scope:** code files only, via an extension **allowlist**. Docs, config, and
  `.md` files never trigger.
- **Skills named in the reminder:** `coding-principles` (always) and
  `architecting-principles` (for structural changes) only. `detecting-code-smells` is
  **excluded** — it is review-time, not write-time, so naming it at edit-time is a false
  trigger.

## Verified technical facts

Confirmed against current Claude Code docs:

- `PreToolUseHookSpecificOutput` includes `additionalContext: NotRequired[str]`, so a
  `PreToolUse` hook can inject context without blocking the edit.
- The reminder output **omits** `permissionDecision`. Omitting it leaves the edit subject
  to the user's normal permission flow. (Setting `"allow"` would silently auto-approve
  every code edit — not wanted.)
- Plugin hooks live in `hooks/hooks.json` (same format as `settings.json`) and are
  auto-discovered. Bundled scripts are referenced via `${CLAUDE_PLUGIN_ROOT}`.
- Official hook examples parse stdin JSON with `bash` + `jq`, so that is the idiomatic,
  lowest-surprise choice for the script. `jq` is a documented dependency.

## Part A — The hook (plugin only)

### Files added

- `hooks/hooks.json` — registers the `PreToolUse` hook.
- `hooks/remind-coding-skills.sh` — the bash + `jq` script (executable).

### `hooks/hooks.json`

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/remind-coding-skills.sh"
          }
        ]
      }
    ]
  }
}
```

### Script logic — `hooks/remind-coding-skills.sh`

Fail-open throughout: any missing field, parse error, or unexpected condition results in
`{}` on stdout and exit 0, so the hook can never block or break an edit.

1. Read stdin JSON. Extract `.session_id` and `.tool_input.file_path` with `jq`.
2. **File filter.** Lowercase the file's extension. If it is not in the code-extension
   allowlist, output `{}` and exit 0.
3. **Once-per-session dedup.** Marker file at
   `${TMPDIR:-/tmp}/claude-coding-skills/<session_id>`. If it exists, output `{}` and
   exit 0. Otherwise `mkdir -p` the parent and `touch` the marker, then continue.
4. **Emit the reminder** and exit 0:

```json
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"About to create or modify code. If you haven't already this session, invoke the coding-principles skill and apply it to this change. For structural changes (new modules/layers, moving code, new cross-module dependencies), also invoke architecting-principles."}}
```

### Code-extension allowlist

Allowlist (not denylist), so unknown extensions stay silent. Initial set — extend as
needed:

```
py ts tsx js jsx mjs cjs go rs java kt kts rb php c h cpp cc cxx hpp cs swift
m mm scala clj cljs ex exs erl sh bash zsh sql vue svelte dart lua r jl pl pm
```

Explicitly **not** included (so they never trigger): `md`, `mdx`, `txt`, `json`, `yaml`,
`yml`, `toml`, `ini`, `lock`, `csv`.

### `plugin.json`

Bump `version` (e.g. `0.3.0` → `0.4.0`) so plugin users pick up the new hook on
`/plugin marketplace update`. `hooks/hooks.json` is auto-discovered; no other manifest
change is required.

## Part B — Description sharpening (all paths)

Tighten the `description:` frontmatter so the model's native skill-selection fires more
often when code work starts. Keep all existing trigger specifics; only lead with the
write moment.

- **`coding-principles`** — lead the trigger list with the write moment, e.g.
  "…especially when about to create or edit a code file…".
- **`architecting-principles`** — ensure structural triggers (new module/layer/service,
  cross-module dependency, moving code) read as imperative.
- **`detecting-code-smells`** — left as-is; it is review-time, not write-time.

Keep the README skills table and `plugin.json` `keywords`/`description` consistent with
any wording changes.

## Testing

### Script unit checks (no framework)

Pipe sample JSON into `remind-coding-skills.sh` and assert stdout:

- `.py` edit on a fresh session → reminder JSON emitted.
- Second call with the same `session_id` → `{}` (dedup works).
- `.md` edit → `{}` (file filter works).
- Malformed / empty stdin → `{}` and exit 0 (fail-open).

These can live as a small shell test script under the repo (e.g. a `test` block in the
implementation plan) — kept minimal, no new test dependency beyond `jq`.

### Manual end-to-end

Install the plugin in a scratch repo, then:

- Edit a `.py` file → reminder appears once.
- Edit again in the same session → silent.
- Edit a `README.md` → silent.

## Docs

- **README:** add a short "Auto-activation" note — the hook is plugin-only; describe the
  once-per-session, code-files-only behavior; note the `jq` dependency.

## Distribution caveat (documented, not solved)

The hook reaches **only** the Claude Code plugin install path. `skills`-CLI and
other-agent users rely on Part B (sharpened descriptions). This is inherent: hooks are
not part of the cross-agent skills format. The README note should state this so the
behavior difference is not surprising.

## Out of scope (YAGNI)

- Per-user-message or per-edit re-firing (chose once-per-session).
- Inlining principle content into the hook (chose reminder-to-invoke; skills stay the
  source of truth).
- Blocking edits until a skill is invoked (chose non-blocking `additionalContext`).
- Auto-activating `detecting-code-smells` at write-time.
- A Node/Python implementation of the script (chose bash + `jq` to match official
  examples and avoid a runtime assumption).
