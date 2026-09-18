#!/usr/bin/env bash
# remind-reply-style.sh
# UserPromptSubmit hook: on the first prompt of a session, remind Claude to
# invoke the matching-altitude skill so replies are pitched at the level of the
# user's message. Fail-open — any error prints {} and exits 0, so a prompt is
# never blocked.
set -u

emit_nothing() { printf '{}\n'; exit 0; }

# jq builds the JSON output; without it, stay silent rather than guess.
command -v jq >/dev/null 2>&1 || emit_nothing

input="$(cat)"
[ -n "$input" ] || emit_nothing

session_id="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"

# Once-per-session dedup via a marker file keyed on the session id.
session_id="$(printf '%s' "$session_id" | tr -cd 'A-Za-z0-9._-')"
if [ -n "$session_id" ]; then
  marker_dir="${TMPDIR:-/tmp}/claude-reply-style"
  marker="$marker_dir/$session_id"
  [ -e "$marker" ] && emit_nothing
  mkdir -p "$marker_dir" 2>/dev/null && : > "$marker" 2>/dev/null
fi

reminder="Before replying, invoke the matching-altitude skill and keep it in mind for the rest of the session. Pitch every reply at the altitude of the message it answers — high-level question, high-level answer; specific question, specific answer — and re-read the altitude each message, it can shift."

jq -cn --arg ctx "$reminder" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
