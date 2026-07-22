#!/usr/bin/env bash
# remind-coding-skills.cursor.sh
# Cursor sessionStart hook: inject a one-time reminder to use the coding skills.
# sessionStart fires once per session, so no dedup is needed. The payload is not
# used. The reminder text is kept identical to the Claude hook
# (hooks/remind-coding-skills.sh) so both tools give the same guidance.
# Fail-open — it always prints the reminder and exits 0, never blocks.
set -u

# Drain stdin so the caller's pipe never blocks; the payload is not needed.
cat >/dev/null 2>&1

printf '%s\n' '{"additional_context":"About to create or modify code. If you haven'\''t already this session, invoke the coding-principles skill and apply it to this change. For structural changes (new modules/layers, moving code, new cross-module dependencies), also invoke architecting-principles."}'

exit 0
