# Cursor Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package this repo's 8 skills + coding-skills reminder hook as an installable Cursor plugin, living in the same repo and sharing the existing `skills/` folder.

**Architecture:** Add a `.cursor-plugin/` manifest pair (`plugin.json` + `marketplace.json`) at the repo root, pointing Cursor at the existing shared `skills/` folder. Translate the one hook to Cursor's `sessionStart` event in a separate `hooks/hooks.cursor.json` + `hooks/remind-coding-skills.cursor.sh`, leaving all Claude Code files untouched.

**Tech Stack:** JSON manifests, POSIX bash hook script, `jq` for JSON validation in tests.

## Global Constraints

- Do not change skill content or the Claude hook's behavior: leave `skills/**`, `hooks/hooks.json`, `hooks/remind-coding-skills.sh`, and `.claude-plugin/marketplace.json` untouched. The ONLY intended Claude-side change is a version bump to `0.6.1` in `.claude-plugin/plugin.json` (Task 3, Step 1) — this branch is a single release: "add Cursor plugin + bump to 0.6.1".
- Cursor skills use the same `name` + `description` frontmatter as Anthropic skills — the `skills/` folder is shared as-is, never copied.
- Cursor plugin `name` MUST be lowercase kebab-case matching `^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$` → use `jedymatt-skills`.
- Plugin `version` MUST match the Claude plugin's current version: `0.6.1`.
- Cursor plugin-root variable is `${CURSOR_PLUGIN_ROOT}` (NOT `${CLAUDE_PLUGIN_ROOT}`).
- The repo has no LICENSE file → omit the `license` field from the Cursor manifest.
- Hook must be fail-open (never blocks) and non-blocking.
- Reminder text (verbatim, reused across Claude + Cursor): `If you are about to create or modify code, invoke the coding-principles skill and apply it to this change. For structural changes (new modules/layers, moving code, or new cross-module dependencies), also invoke architecting-principles.`

---

### Task 1: Cursor hook script + test (`sessionStart` reminder)

**Files:**
- Create: `hooks/remind-coding-skills.cursor.sh`
- Test: `hooks/test-remind-coding-skills.cursor.sh`

**Interfaces:**
- Consumes: stdin JSON (Cursor `sessionStart` payload — drained and ignored).
- Produces: stdout JSON `{"additional_context": "<reminder>"}` on success; the reminder string contains the substrings `coding-principles` and `architecting-principles`. Exit code always `0`.

- [ ] **Step 1: Write the failing test**

Create `hooks/test-remind-coding-skills.cursor.sh`:

```bash
#!/usr/bin/env bash
# test-remind-coding-skills.cursor.sh — run: bash hooks/test-remind-coding-skills.cursor.sh
set -u
HOOK="$(cd "$(dirname "$0")" && pwd)/remind-coding-skills.cursor.sh"
fail=0

run() { bash "$HOOK"; }

assert_contains() {
  case "$1" in
    *"$2"*) echo "PASS: $3" ;;
    *) echo "FAIL: $3 — expected to contain '$2', got: $1"; fail=1 ;;
  esac
}

# 1: sessionStart payload → reminder with both skills
out="$(printf '%s' '{"session_id":"sess-A","is_background_agent":false,"composer_mode":"agent"}' | run)"
assert_contains "$out" "coding-principles" "sessionStart emits coding-principles reminder"
assert_contains "$out" "architecting-principles" "reminder mentions architecting-principles"
assert_contains "$out" "additional_context" "output uses additional_context field"

# 2: output is valid JSON
if printf '%s' "$out" | jq -e . >/dev/null 2>&1; then echo "PASS: output is valid JSON"; else
  echo "FAIL: output is not valid JSON — got: $out"; fail=1; fi

# 3: empty stdin → still emits reminder, exit 0
out="$(printf '%s' '' | run)"; rc=$?
assert_contains "$out" "coding-principles" "empty stdin still emits reminder"
[ "$rc" -eq 0 ] && echo "PASS: empty stdin exits 0" || { echo "FAIL: empty stdin exit code $rc"; fail=1; }

# 4: malformed stdin → still emits reminder, exit 0 (payload is ignored)
out="$(printf '%s' '{not json' | run)"; rc=$?
assert_contains "$out" "coding-principles" "malformed stdin still emits reminder"
[ "$rc" -eq 0 ] && echo "PASS: malformed stdin exits 0" || { echo "FAIL: malformed stdin exit code $rc"; fail=1; }

[ "$fail" -eq 0 ] && echo "All tests passed." || echo "Some tests failed."
exit $fail
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash hooks/test-remind-coding-skills.cursor.sh`
Expected: FAIL — the hook script does not exist yet (`bash: .../remind-coding-skills.cursor.sh: No such file or directory`), tests report failures, non-zero exit.

- [ ] **Step 3: Write the hook script**

Create `hooks/remind-coding-skills.cursor.sh`:

```bash
#!/usr/bin/env bash
# remind-coding-skills.cursor.sh
# Cursor sessionStart hook: inject a one-time reminder to use the coding skills.
# sessionStart fires once per session, so no dedup is needed. The payload is not
# used. Fail-open — it can only print the reminder or nothing, never blocks.
set -u

# Drain stdin so the caller's pipe never blocks; the payload is not needed.
cat >/dev/null 2>&1

printf '%s\n' '{"additional_context":"If you are about to create or modify code, invoke the coding-principles skill and apply it to this change. For structural changes (new modules/layers, moving code, or new cross-module dependencies), also invoke architecting-principles."}'
```

- [ ] **Step 4: Make the script executable**

Run: `chmod +x hooks/remind-coding-skills.cursor.sh`
Expected: no output, exit 0.

- [ ] **Step 5: Run test to verify it passes**

Run: `bash hooks/test-remind-coding-skills.cursor.sh`
Expected: every line `PASS: …`, final line `All tests passed.`, exit 0.

- [ ] **Step 6: Commit**

```bash
git add hooks/remind-coding-skills.cursor.sh hooks/test-remind-coding-skills.cursor.sh
git commit -m "🪝 feat(cursor): add sessionStart coding-skills reminder hook + test"
```

---

### Task 2: Cursor hook manifest (`hooks.cursor.json`)

**Files:**
- Create: `hooks/hooks.cursor.json`

**Interfaces:**
- Consumes: `hooks/remind-coding-skills.cursor.sh` (from Task 1), referenced via `${CURSOR_PLUGIN_ROOT}`.
- Produces: a Cursor hooks manifest wiring `sessionStart` → the script. Referenced by `.cursor-plugin/plugin.json` `"hooks"` field (Task 3).

- [ ] **Step 1: Write the hooks manifest**

Create `hooks/hooks.cursor.json`:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "command": "${CURSOR_PLUGIN_ROOT}/hooks/remind-coding-skills.cursor.sh"
      }
    ]
  }
}
```

- [ ] **Step 2: Verify it is valid JSON**

Run: `jq -e . hooks/hooks.cursor.json >/dev/null && echo OK`
Expected: `OK` (exit 0).

- [ ] **Step 3: Verify the referenced script path resolves**

Run: `test -x "hooks/$(jq -r '.hooks.sessionStart[0].command' hooks/hooks.cursor.json | sed 's#.*/hooks/##')" && echo EXECUTABLE`
Expected: `EXECUTABLE` — confirms `remind-coding-skills.cursor.sh` exists and is executable.

- [ ] **Step 4: Commit**

```bash
git add hooks/hooks.cursor.json
git commit -m "🪝 feat(cursor): wire sessionStart hook in hooks.cursor.json"
```

---

### Task 3: Cursor plugin manifest (`.cursor-plugin/plugin.json`)

**Files:**
- Create: `.cursor-plugin/plugin.json`

**Interfaces:**
- Consumes: the shared `skills/` folder and `hooks/hooks.cursor.json` (Task 2).
- Produces: the per-plugin manifest Cursor reads. Declares `skills` and `hooks` discovery paths. Also aligns `.claude-plugin/plugin.json` to `0.6.1` so both manifests match.

- [ ] **Step 1: Bump the Claude plugin version to 0.6.1**

Edit `.claude-plugin/plugin.json`, change the `version` field from `0.6.0` to `0.6.1`. (On the current working branch this edit may already be present — verify the value is `0.6.1`.)

Run: `[ "$(jq -r '.version' .claude-plugin/plugin.json)" = "0.6.1" ] && echo OK`
Expected: `OK`.

- [ ] **Step 2: Write the plugin manifest**

Create `.cursor-plugin/plugin.json`:

```json
{
  "name": "jedymatt-skills",
  "displayName": "jedymatt Skills",
  "version": "0.6.1",
  "description": "jedymatt's personal skills: coding-principles, architecting-principles, detecting-code-smells, git-town (with PR stacking), handoff/load-handoff, and writing-plain-english.",
  "author": {
    "name": "jedymatt"
  },
  "homepage": "https://github.com/jedymatt/skills",
  "repository": "https://github.com/jedymatt/skills",
  "keywords": [
    "skills",
    "coding-principles",
    "architecting-principles",
    "detecting-code-smells",
    "git-town",
    "stacking-prs",
    "handoff",
    "writing-plain-english"
  ],
  "category": "developer-tools",
  "skills": "./skills/",
  "hooks": "./hooks/hooks.cursor.json"
}
```

- [ ] **Step 3: Verify it is valid JSON**

Run: `jq -e . .cursor-plugin/plugin.json >/dev/null && echo OK`
Expected: `OK`.

- [ ] **Step 4: Verify name matches kebab-case pattern and version matches Claude manifest**

Run:
```bash
jq -r '.name' .cursor-plugin/plugin.json | grep -Eq '^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$' && echo "NAME OK"
[ "$(jq -r '.version' .cursor-plugin/plugin.json)" = "$(jq -r '.version' .claude-plugin/plugin.json)" ] && echo "VERSION MATCHES"
```
Expected: `NAME OK` and `VERSION MATCHES`.

- [ ] **Step 5: Verify declared discovery paths exist**

Run:
```bash
test -d "$(jq -r '.skills' .cursor-plugin/plugin.json)" && echo "SKILLS DIR OK"
test -f "$(jq -r '.hooks' .cursor-plugin/plugin.json)" && echo "HOOKS FILE OK"
```
Expected: `SKILLS DIR OK` and `HOOKS FILE OK`.

- [ ] **Step 6: Commit**

```bash
git add .cursor-plugin/plugin.json .claude-plugin/plugin.json
git commit -m "📦 feat(cursor): add .cursor-plugin/plugin.json manifest; bump to 0.6.1"
```

---

### Task 4: Cursor marketplace manifest (`.cursor-plugin/marketplace.json`)

**Files:**
- Create: `.cursor-plugin/marketplace.json`

**Interfaces:**
- Consumes: the plugin declared in Task 3 (`name: jedymatt-skills`).
- Produces: the marketplace manifest listing the single plugin with `source: "."`.

- [ ] **Step 1: Write the marketplace manifest**

Create `.cursor-plugin/marketplace.json`:

```json
{
  "name": "jedymatt",
  "owner": {
    "name": "jedymatt",
    "url": "https://github.com/jedymatt"
  },
  "metadata": {
    "description": "jedymatt's personal Cursor plugin: coding/architecting principles, code-smell detection, git-town workflows, session handoff, and plain-English writing."
  },
  "plugins": [
    {
      "name": "jedymatt-skills",
      "source": ".",
      "description": "jedymatt's personal skills: coding-principles, architecting-principles, detecting-code-smells, git-town (with PR stacking), handoff/load-handoff, and writing-plain-english."
    }
  ]
}
```

- [ ] **Step 2: Verify it is valid JSON**

Run: `jq -e . .cursor-plugin/marketplace.json >/dev/null && echo OK`
Expected: `OK`.

- [ ] **Step 3: Verify the plugin name matches the plugin manifest**

Run: `[ "$(jq -r '.plugins[0].name' .cursor-plugin/marketplace.json)" = "$(jq -r '.name' .cursor-plugin/plugin.json)" ] && echo "NAMES MATCH"`
Expected: `NAMES MATCH`.

- [ ] **Step 4: Commit**

```bash
git add .cursor-plugin/marketplace.json
git commit -m "📦 feat(cursor): add .cursor-plugin/marketplace.json"
```

---

### Task 5: Document Cursor install + confirm Claude plugin untouched

**Files:**
- Modify: `README.md` (add a "Use in Cursor" section near the existing install/usage docs)

**Interfaces:**
- Consumes: nothing new.
- Produces: user-facing install docs; a verification that Claude Code files are byte-for-byte unchanged.

- [ ] **Step 1: Confirm no skill content or Claude hook behavior changed on this branch**

Run: `git diff --name-only main...HEAD -- hooks/hooks.json hooks/remind-coding-skills.sh .claude-plugin/marketplace.json 'skills/**'`
Expected: **empty output** (skills, the Claude hook, and the Claude marketplace are untouched). If anything lists, stop and revert that change.

Then confirm the ONLY change under `.claude-plugin/` is the version bump:

Run: `git diff main...HEAD -- .claude-plugin/plugin.json | grep -E '^[+-]' | grep -v '^[+-][+-]'`
Expected: only the `version` line changed — a `-  "version": "0.6.0",` and a `+  "version": "0.6.1",`. Anything else means stop and revert.

- [ ] **Step 2: Run the Claude hook's existing test to prove it still passes**

Run: `bash hooks/test-remind-coding-skills.sh`
Expected: `All tests passed.`, exit 0.

- [ ] **Step 3: Add the "Use in Cursor" section to README.md**

Append this section to `README.md` (place it after the existing Claude Code install/usage section — match surrounding heading level and tone):

```markdown
## Use in Cursor

This repo doubles as a **Cursor plugin**. The same 8 skills work in Cursor unchanged
(Cursor reads the same `skills/<name>/SKILL.md` format), plus a `sessionStart` hook that
reminds the agent to use `coding-principles` / `architecting-principles`.

- Cursor manifest: `.cursor-plugin/plugin.json`
- Cursor marketplace entry: `.cursor-plugin/marketplace.json`
- Cursor hook: `hooks/hooks.cursor.json` → `hooks/remind-coding-skills.cursor.sh`

Install it from the Cursor marketplace, or point Cursor at this repo. The Claude Code
plugin (`.claude-plugin/`, `hooks/hooks.json`) is unaffected — both tools read their own
manifests from the same repo and share the `skills/` folder.
```

- [ ] **Step 4: Verify the README renders the new section**

Run: `grep -q "## Use in Cursor" README.md && echo OK`
Expected: `OK`.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "📖 docs: document Cursor plugin install alongside Claude Code"
```

---

## Post-implementation (manual, outside the plan)

These require a running Cursor install and are not automatable here — do them after merge:

- Install the plugin in Cursor and confirm all 8 skills appear and are invocable.
- Start a Cursor session and confirm the `sessionStart` reminder shows up in context.
- Confirm the hook fires in both the Cursor editor and the Cursor CLI (`cursor-agent`).
- If Cursor rejects `source: "."`, move the plugin into a subdirectory per Cursor's
  multi-plugin convention (tracked as an open item in the spec).
