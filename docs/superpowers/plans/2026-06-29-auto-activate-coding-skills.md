# Auto-activate Coding Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When Claude is about to edit a code file, remind it to invoke `coding-principles` (and `architecting-principles` for structural changes) — reliably via a plugin hook, best-effort via sharpened skill descriptions everywhere else.

**Architecture:** A `PreToolUse` hook (bash + `jq`) matches `Edit|Write|MultiEdit`, and on the first code-file edit of a session injects a reminder through `additionalContext`. It fires once per session (marker file) and only for code-file extensions (allowlist). Separately, the `coding-principles` and `architecting-principles` skill descriptions are sharpened so the model's native activation fires more often on the cross-agent skills-CLI path, which can't carry hooks.

**Tech Stack:** Bash, `jq`, Claude Code plugin hooks (`hooks/hooks.json`, `${CLAUDE_PLUGIN_ROOT}`).

**Spec:** `docs/superpowers/specs/2026-06-29-auto-activate-coding-skills-design.md`

## Global Constraints

- **Fail-open:** the hook must never block or break an edit. Every path prints `{}` and exits `0` on any missing field, parse error, or unmet condition.
- **No `permissionDecision` in output** — the edit stays subject to the user's normal permission flow. (`"allow"` would silently auto-approve every code edit.)
- **Skills stay the single source of truth** — the hook reminds Claude to *invoke* the skills; it never inlines their content.
- **Bash + `jq` only** — no Node/Python runtime assumption (matches official Claude Code hook examples).
- **Reminder names only `coding-principles` + `architecting-principles`** — never `detecting-code-smells` (it is review-time, not write-time).
- **Code files only**, via an extension allowlist; **once per session**, via a marker file keyed on `session_id`.
- **No drive-by edits** to unrelated code or skills.
- Commit messages: sentence-case imperative (match repo history, e.g. "Add …"), no `feat:`/`fix:` prefix; end each with the `Co-Authored-By` trailer.

## File Structure

- `hooks/remind-coding-skills.sh` (create) — the hook script: parse payload, filter by extension, dedup per session, emit reminder. Executable.
- `hooks/test-remind-coding-skills.sh` (create) — shell tests for the script.
- `hooks/hooks.json` (create) — registers the `PreToolUse` hook in the plugin.
- `skills/coding-principles/SKILL.md` (modify, line 3) — sharpen `description`.
- `skills/architecting-principles/SKILL.md` (modify, line 3) — sharpen `description`.
- `README.md` (modify) — add an "Auto-activation" section.
- `.claude-plugin/plugin.json` (modify, line 3) — bump `version`.

---

### Task 1: Hook script + tests

**Files:**
- Create: `hooks/remind-coding-skills.sh`
- Test: `hooks/test-remind-coding-skills.sh`

**Interfaces:**
- Consumes: hook payload JSON on stdin with `.session_id` (string) and `.tool_input.file_path` (string).
- Produces: on stdout, either `{}` (silent) or
  `{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"<reminder>"}}`.
  Always exits `0`. Marker files at `${TMPDIR:-/tmp}/claude-coding-skills/<session_id>`.

- [ ] **Step 1: Write the failing test**

Create `hooks/test-remind-coding-skills.sh`:

```bash
#!/usr/bin/env bash
# test-remind-coding-skills.sh — run: bash hooks/test-remind-coding-skills.sh
set -u
HOOK="$(cd "$(dirname "$0")" && pwd)/remind-coding-skills.sh"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT
fail=0

run() { TMPDIR="$TMPROOT" bash "$HOOK"; }

assert_contains() {
  case "$1" in
    *"$2"*) echo "PASS: $3" ;;
    *) echo "FAIL: $3 — expected to contain '$2', got: $1"; fail=1 ;;
  esac
}
assert_equals() {
  if [ "$1" = "$2" ]; then echo "PASS: $3"; else
    echo "FAIL: $3 — expected '$2', got: $1"; fail=1; fi
}

# 1: code file on a fresh session → reminder
out="$(printf '%s' '{"session_id":"sess-A","tool_input":{"file_path":"/x/foo.py"}}' | run)"
assert_contains "$out" "coding-principles" "code file emits reminder"

# 2: same session again → silent
out="$(printf '%s' '{"session_id":"sess-A","tool_input":{"file_path":"/x/bar.py"}}' | run)"
assert_equals "$out" "{}" "second edit in same session is silent"

# 3: markdown file (fresh session) → silent
out="$(printf '%s' '{"session_id":"sess-B","tool_input":{"file_path":"/x/README.md"}}' | run)"
assert_equals "$out" "{}" "markdown file is silent"

# 4: empty / malformed stdin → silent, exit 0
out="$(printf '%s' '' | run)"; rc=$?
assert_equals "$out" "{}" "empty stdin is silent"
[ "$rc" -eq 0 ] && echo "PASS: empty stdin exits 0" || { echo "FAIL: empty stdin exit code $rc"; fail=1; }

[ "$fail" -eq 0 ] && echo "All tests passed." || echo "Some tests failed."
exit $fail
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash hooks/test-remind-coding-skills.sh`
Expected: FAIL — `remind-coding-skills.sh` does not exist yet, so test 1 prints
`FAIL: code file emits reminder …` and the script exits non-zero.

- [ ] **Step 3: Write the hook script**

Create `hooks/remind-coding-skills.sh`:

```bash
#!/usr/bin/env bash
# remind-coding-skills.sh
# PreToolUse hook (Edit|Write|MultiEdit): on the first code-file edit of a
# session, remind Claude to invoke the coding skills. Fail-open — any error or
# unmet condition prints {} and exits 0, so an edit is never blocked.
set -u

emit_nothing() { printf '{}'; exit 0; }

# jq parses the hook payload; without it, stay silent rather than guess.
command -v jq >/dev/null 2>&1 || emit_nothing

input="$(cat)"
[ -n "$input" ] || emit_nothing

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
session_id="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"

[ -n "$file_path" ] || emit_nothing

# File filter: only known code extensions trigger the reminder.
ext="${file_path##*.}"
ext="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"
case " py ts tsx js jsx mjs cjs go rs java kt kts rb php c h cpp cc cxx hpp cs swift m mm scala clj cljs ex exs erl sh bash zsh sql vue svelte dart lua r jl pl pm " in
  *" $ext "*) ;;
  *) emit_nothing ;;
esac

# Once-per-session dedup via a marker file keyed on the session id.
session_id="$(printf '%s' "$session_id" | tr -cd 'A-Za-z0-9._-')"
if [ -n "$session_id" ]; then
  marker_dir="${TMPDIR:-/tmp}/claude-coding-skills"
  marker="$marker_dir/$session_id"
  [ -e "$marker" ] && emit_nothing
  mkdir -p "$marker_dir" 2>/dev/null && : > "$marker" 2>/dev/null
fi

reminder="About to create or modify code. If you haven't already this session, invoke the coding-principles skill and apply it to this change. For structural changes (new modules/layers, moving code, new cross-module dependencies), also invoke architecting-principles."

jq -cn --arg ctx "$reminder" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$ctx}}'
```

- [ ] **Step 4: Make the script executable**

Run: `chmod +x hooks/remind-coding-skills.sh`
Expected: no output, exit 0.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash hooks/test-remind-coding-skills.sh`
Expected: PASS for all five assertions, final line `All tests passed.`, exit 0.

- [ ] **Step 6: Commit**

```bash
git add hooks/remind-coding-skills.sh hooks/test-remind-coding-skills.sh
git commit -m "Add coding-skills reminder hook script and tests

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Wire the hook into the plugin

**Files:**
- Create: `hooks/hooks.json`

**Interfaces:**
- Consumes: `hooks/remind-coding-skills.sh` from Task 1 (referenced via `${CLAUDE_PLUGIN_ROOT}`).
- Produces: an auto-discovered plugin hook registration. No code depends on this file.

- [ ] **Step 1: Create `hooks/hooks.json`**

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

- [ ] **Step 2: Verify it is valid JSON with the expected shape**

Run: `jq -e '.hooks.PreToolUse[0].matcher == "Edit|Write|MultiEdit" and (.hooks.PreToolUse[0].hooks[0].command | test("remind-coding-skills.sh$"))' hooks/hooks.json`
Expected: prints `true`, exit 0.

- [ ] **Step 3: Commit**

```bash
git add hooks/hooks.json
git commit -m "Register PreToolUse coding-skills reminder hook

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Sharpen skill descriptions

**Files:**
- Modify: `skills/coding-principles/SKILL.md:3`
- Modify: `skills/architecting-principles/SKILL.md:3`

**Interfaces:**
- Consumes: nothing.
- Produces: descriptions that lead with the write moment so native skill-selection fires when code work starts. No code depends on this.

- [ ] **Step 1: Edit `coding-principles` description**

Replace the `description:` line (line 3) exactly:

OLD:
```
description: Use when writing, modifying, refactoring, or reviewing code — especially when about to extract duplicated logic, add a parameter to an existing function, pass a true/false argument, inline a numeric literal, write an explanatory comment, reach through an object's internals, or add abstraction or configuration for a future need.
```

NEW:
```
description: Use when writing, modifying, refactoring, or reviewing code — especially when about to create or edit a code file, extract duplicated logic, add a parameter to an existing function, pass a true/false argument, inline a numeric literal, write an explanatory comment, reach through an object's internals, or add abstraction or configuration for a future need.
```

- [ ] **Step 2: Edit `architecting-principles` description**

Replace the `description:` line (line 3) exactly:

OLD:
```
description: Use when designing or changing how code is organized across modules, packages, or components — especially when about to add a new module/layer/service, decide where new code lives, introduce a dependency between parts, create a `utils`/`shared`/`common` bucket, wire a module directly to an external system (DB/HTTP/SDK/vendor), split or merge modules, or add a structural boundary for a future need.
```

NEW:
```
description: Use when designing or changing how code is organized across modules, packages, or components — especially when about to create or edit code that changes structure: add a new module/layer/service, decide where new code lives, introduce a dependency between parts, create a `utils`/`shared`/`common` bucket, wire a module directly to an external system (DB/HTTP/SDK/vendor), split or merge modules, or add a structural boundary for a future need.
```

- [ ] **Step 3: Verify the new phrasing is present and frontmatter is intact**

Run: `grep -q "create or edit a code file" skills/coding-principles/SKILL.md && grep -q "create or edit code that changes structure" skills/architecting-principles/SKILL.md && head -1 skills/coding-principles/SKILL.md | grep -qx -- "---" && head -1 skills/architecting-principles/SKILL.md | grep -qx -- "---" && echo OK`
Expected: prints `OK`, exit 0.

- [ ] **Step 4: Commit**

```bash
git add skills/coding-principles/SKILL.md skills/architecting-principles/SKILL.md
git commit -m "Lead coding/architecting skill descriptions with the write moment

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: README note + version bump

**Files:**
- Modify: `README.md`
- Modify: `.claude-plugin/plugin.json:3`

**Interfaces:**
- Consumes: the hook (Task 1–2) and sharpened descriptions (Task 3) — this task documents and releases them.
- Produces: user-facing docs and a new plugin version so `/plugin marketplace update` picks up the hook.

- [ ] **Step 1: Add an "Auto-activation" section to `README.md`**

Insert this section immediately after the Skills table (after the line for `writing-plain-english`, before `## Install with the skills CLI (any agent)`):

```markdown
## Auto-activation

Installed as a **Claude Code plugin**, a `PreToolUse` hook reminds Claude to invoke `coding-principles` (and `architecting-principles` for structural changes) the first time it edits a **code file** in a session. It fires once per session, only for code-file extensions (not `.md`, docs, or config), and never blocks the edit. Requires [`jq`](https://jqlang.github.io/jq/).

The hook ships only with the plugin install path. With the [`skills`](https://skills.sh) CLI (or other agents), the skills' descriptions still prompt activation on their own — best-effort, since that path can't bundle hooks.
```

- [ ] **Step 2: Bump the plugin version**

In `.claude-plugin/plugin.json`, change line 3 exactly:

OLD:
```
  "version": "0.3.0",
```

NEW:
```
  "version": "0.4.0",
```

- [ ] **Step 3: Verify the docs and version**

Run: `grep -q "## Auto-activation" README.md && jq -e '.version == "0.4.0"' .claude-plugin/plugin.json`
Expected: `grep` succeeds and `jq` prints `true`, exit 0.

- [ ] **Step 4: Commit**

```bash
git add README.md .claude-plugin/plugin.json
git commit -m "Document auto-activation hook and bump plugin to 0.4.0

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Manual end-to-end verification (after all tasks)

In a scratch repo with the plugin installed (`/plugin marketplace update` then reload):

1. Edit a `.py` file → the reminder appears once.
2. Edit another code file in the same session → silent.
3. Edit a `README.md` → silent.

## Notes / risks

- `additionalContext` on `PreToolUse` is confirmed in the current Claude Code `PreToolUseHookSpecificOutput` type. If a future version drops it, fall back to surfacing the reminder via `permissionDecisionReason` with `permissionDecision: "ask"` (more intrusive) — out of scope unless that regression appears.
- `jq` is a hard dependency of both the hook and its tests; documented in the README.
