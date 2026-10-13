---
name: reviewing-for-risk
description: Use when reviewing a PR, diff, branch, or stack before merge and the question is what could go wrong once it ships — data corruption or loss, overwrites, unreadable records, security or tenant leaks, a flow broken on merge — or when asked "is this safe to merge?", "is this a blocker?", "what's the worst that could happen?", "could this lose data?". Also when the PR calls risky code in an already-approved parent branch. Not for style or design smells (detecting-code-smells).
---

# Reviewing for Risk

## Overview

Rank what a change could do to stored data and to users, worst first. In a single "most severe first" list, a likely UI glitch ends up above a silent overwrite. Tiers stop that.

## Follow every write past the diff

For each value the PR sends, writes, or deletes, trace it to what gets stored and to the next read. Follow it through code outside the diff too: an approved parent PR, a shared helper, the database client. This PR may be the first caller to reach a bad path in code that was approved elsewhere.

- **What is stored afterwards?** Check the driver and serialiser defaults for `undefined`, missing keys, and dates.
- **Does the next read still parse?** If the parse runs after the write, the bad data is already saved.
- **What else does the write replace?** Fields, items, or links the user never touched.
- **Does a sibling flow guard the same write** with a snapshot, a version check, or an owner filter that this one skips?

## Sort findings into tiers

1. **Stored data:** corrupted, lost, overwritten, or left unreadable.
2. **Security:** a missing check, data crossing users or tenants, or untrusted input that's trusted.
3. **Broken on merge:** a flow that stops working, with no data damage.
4. **Everything else:** UI glitches, error handling, test gaps.

Every tier 1 or 2 finding ranks above every tier 3 or 4 finding, however likely the lower one is. If a UI bug causes data damage, it goes in tier 1, stated as the data damage.

## Each finding has these parts

```
N. [tier] [blocker | follow-up | question]: what goes wrong, in one line
   Path: user action → … → damage, with file:line
   Worst case: who it hits, how many, and whether it can be undone (snapshot, backup, or only a manual repair)
   Fix: the smallest change, and which PR it belongs in
```

- **blocker:** tier 1 or 2 reachable through a normal action, or any tier 3.
- **follow-up:** needs an unusual path, or is cheap to undo.
- **question:** the right behaviour is a product call. Name who decides (**spotting-product-decisions**).

End with one line: safe to merge, or the blockers that have to be fixed first.

If nothing is found, say so and list what you traced (writes, reads, auth checks). Don't fill the list with smells.

## Common mistakes

- **Reviewing only the diff** when it now calls code that writes.
- **Trusting a validation that runs before the write.** What matters is what gets stored and whether it reads back.
- **Talking a data finding down** ("the candidate overstates it"). State the worst case and let the user weigh it.
