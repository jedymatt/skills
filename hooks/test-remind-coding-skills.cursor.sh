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
