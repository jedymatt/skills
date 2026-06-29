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
