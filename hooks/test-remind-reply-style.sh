#!/usr/bin/env bash
# test-remind-reply-style.sh — run: bash hooks/test-remind-reply-style.sh
set -u
HOOK="$(cd "$(dirname "$0")" && pwd)/remind-reply-style.sh"
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

# 1: first prompt of a session → reminder
out="$(printf '%s' '{"session_id":"sess-A","prompt":"why is this slow"}' | run)"
assert_contains "$out" "matching-altitude" "first prompt emits reminder"
assert_contains "$out" "UserPromptSubmit" "output names the UserPromptSubmit event"

# 2: same session again → silent
out="$(printf '%s' '{"session_id":"sess-A","prompt":"and now"}' | run)"
assert_equals "$out" "{}" "second prompt in same session is silent"

# 3: a different session → reminder again
out="$(printf '%s' '{"session_id":"sess-B","prompt":"hello"}' | run)"
assert_contains "$out" "matching-altitude" "new session emits reminder"

# 4: empty stdin → silent, exit 0
out="$(printf '%s' '' | run)"; rc=$?
assert_equals "$out" "{}" "empty stdin is silent"
[ "$rc" -eq 0 ] && echo "PASS: empty stdin exits 0" || { echo "FAIL: empty stdin exit code $rc"; fail=1; }

# 5: malformed (non-empty) JSON → reminder, exit 0 (dedup can't key, by design)
out="$(printf '%s' '{"session_id":' | run)"; rc=$?
assert_contains "$out" "matching-altitude" "malformed JSON still emits reminder"
[ "$rc" -eq 0 ] && echo "PASS: malformed JSON exits 0" || { echo "FAIL: malformed JSON exit code $rc"; fail=1; }

# 6: no session_id → reminder still fires (dedup can't key, by design)
out="$(printf '%s' '{"prompt":"hi"}' | run)"
assert_contains "$out" "matching-altitude" "absent session_id still emits reminder"

# 7: output is valid JSON
if printf '%s' "$out" | jq -e . >/dev/null 2>&1; then echo "PASS: output is valid JSON"; else
  echo "FAIL: output is not valid JSON — got: $out"; fail=1; fi

[ "$fail" -eq 0 ] && echo "All tests passed." || echo "Some tests failed."
exit $fail
