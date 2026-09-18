#!/usr/bin/env bash
# test-remind-reply-style.cursor.sh — run: bash hooks/test-remind-reply-style.cursor.sh
set -u
HOOK="$(cd "$(dirname "$0")" && pwd)/remind-reply-style.cursor.sh"
fail=0

run() { bash "$HOOK"; }

assert_contains() {
  case "$1" in
    *"$2"*) echo "PASS: $3" ;;
    *) echo "FAIL: $3 — expected to contain '$2', got: $1"; fail=1 ;;
  esac
}

# 1: sessionStart payload → reminder, exit 0
out="$(printf '%s' '{"session_id":"sess-A","is_background_agent":false,"composer_mode":"agent"}' | run)"; rc=$?
assert_contains "$out" "matching-altitude" "sessionStart emits matching-altitude reminder"
assert_contains "$out" "additional_context" "output uses additional_context field"
[ "$rc" -eq 0 ] && echo "PASS: valid payload exits 0" || { echo "FAIL: valid payload exit code $rc"; fail=1; }

# 2: output is valid JSON
if printf '%s' "$out" | jq -e . >/dev/null 2>&1; then echo "PASS: output is valid JSON"; else
  echo "FAIL: output is not valid JSON — got: $out"; fail=1; fi

# 3: empty stdin → still emits reminder, exit 0
out="$(printf '%s' '' | run)"; rc=$?
assert_contains "$out" "matching-altitude" "empty stdin still emits reminder"
[ "$rc" -eq 0 ] && echo "PASS: empty stdin exits 0" || { echo "FAIL: empty stdin exit code $rc"; fail=1; }

# 4: malformed stdin → still emits reminder, exit 0 (payload is ignored)
out="$(printf '%s' '{not json' | run)"; rc=$?
assert_contains "$out" "matching-altitude" "malformed stdin still emits reminder"
[ "$rc" -eq 0 ] && echo "PASS: malformed stdin exits 0" || { echo "FAIL: malformed stdin exit code $rc"; fail=1; }

# 5: the reminder text matches the Claude hook's, word for word
claude_text="$(printf '%s' '{"session_id":"text-check"}' | TMPDIR="$(mktemp -d)" bash "$(dirname "$HOOK")/remind-reply-style.sh" | jq -r '.hookSpecificOutput.additionalContext')"
cursor_text="$(printf '%s' "$out" | jq -r '.additional_context')"
if [ "$claude_text" = "$cursor_text" ]; then echo "PASS: both hooks give identical guidance"; else
  echo "FAIL: reminder text differs — claude: '$claude_text' cursor: '$cursor_text'"; fail=1; fi

[ "$fail" -eq 0 ] && echo "All tests passed." || echo "Some tests failed."
exit $fail
