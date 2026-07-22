#!/usr/bin/env bash
# remind-coding-skills.cursor.sh
# Cursor sessionStart hook: inject a one-time reminder to use the coding skills.
# sessionStart fires once per session, so no dedup is needed. The payload is not
# used. Fail-open — it can only print the reminder or nothing, never blocks.
set -u

# Drain stdin so the caller's pipe never blocks; the payload is not needed.
cat >/dev/null 2>&1

printf '%s\n' '{"additional_context":"If you are about to create or modify code, invoke the coding-principles skill and apply it to this change. For structural changes (new modules/layers, moving code, or new cross-module dependencies), also invoke architecting-principles."}'
