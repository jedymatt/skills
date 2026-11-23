# Trust boundary: where a rule is enforced

The server is the guard; the UI is a preview. A handmade request (curl, devtools, an old tab, a script, another client) reaches the endpoint without passing through any component, so a rule holds only where the server enforces it.

A rule here is anything users must not get around: validation, a duplicate or uniqueness check, a locked or never-overwrite field, a required value, a permission, a limit.

## Steps

1. **Name the server check first.** For each rule, name the endpoint or write function that rejects the bad request, and the error it returns. This is the fix, and it goes in the same PR as the UI change.
2. **Put it at the shared entry point.** Choose the spot every path to the write passes (the middleware, the one write function), so a sibling endpoint can't skip it.
3. **Require what the check depends on.** A check that runs only when the client sends a field is skipped by a request that leaves the field out. Make the field required, or derive the value on the server.
4. **Decide from what's stored, at write time.** The client's copy can be stale (lists refresh, two tabs, two users), so the server reads the database when it writes, not what the client saw.
5. **Check every item before writing any.** When one request writes several records, validate them all first, so a rejection can't leave half the request applied (or half the emails sent).
6. **Then add the UI check.** Show the problem before the user submits, with the same rule (a shared function, or the server's error shown in place) so the two can't drift.
7. **Update the scope.** If the plan or PR said "UI-only" or "no backend change", that described the fix before this rule existed. Say the server check is now part of it and rewrite that line.

Done when every rule in the plan names the server code that rejects it, and the PR description matches.

## Rationalizations

| Excuse | Reality |
|---|---|
| "The UI already blocks it, so no backend change is needed" | A handmade request gets through. The endpoint rejects it; the UI check only shows it sooner. |
| "The plan says no backend change; the server guard can be a follow-up" | The hole ships first and the follow-up waits. Add the guard to this PR and update the plan. |
| "The server check is only needed if the client's list is partial or stale" | The request itself can come from anywhere. Completeness of the client's data is beside the point. |
| "The client sends a flag, so the server can check it" | A request without the flag skips the check. Require it or derive it on the server. |
| "I added the check to the endpoint in the report" | Sibling endpoints that write the same data are still open. Move it to the shared entry point. |

## Red flags

- A validation, lock, or uniqueness rule that lives only in a component
- A fix plan made only of UI changes for a report that asks to "prevent" or "block" something
- A server check wrapped in `if (body.someField)` where the client may omit the field
- The same check added to one endpoint while sibling endpoints write the same data
