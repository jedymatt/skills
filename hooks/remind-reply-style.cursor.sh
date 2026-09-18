#!/usr/bin/env bash
# remind-reply-style.cursor.sh
# Cursor sessionStart hook: inject a one-time reminder to use the
# matching-altitude skill when replying. sessionStart fires once per session, so
# no dedup is needed. The payload is not used. The reminder text is kept
# identical to the Claude hook (hooks/remind-reply-style.sh) so both tools give
# the same guidance. Fail-open — it always prints the reminder and exits 0.
set -u

# Drain stdin so the caller's pipe never blocks; the payload is not needed.
cat >/dev/null 2>&1

printf '%s\n' '{"additional_context":"Before replying, invoke the matching-altitude skill and keep it in mind for the rest of the session. Pitch every reply at the altitude of the message it answers — high-level question, high-level answer; specific question, specific answer — and re-read the altitude each message, it can shift."}'

exit 0
