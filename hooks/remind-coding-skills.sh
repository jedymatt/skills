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
