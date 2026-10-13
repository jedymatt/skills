---
name: weighing-future-proofing
description: Use when a choice turns on a need that might come later — about to add a parameter, interface, package, layer, config flag, extension point, version field, or a more general data shape "for later", "in case", or "so X can use it later"; choosing between building only what the task needs and building for a mentioned but unscheduled need; about to recommend one side and add "or do you want X now?" or "tell me if you'd rather"; or when the user asks "should we future-proof this?", "is this YAGNI?", or "build it now or later?".
---

# Weighing Future-Proofing

## Overview

Building for a later need and building only what the task needs are both valid. Neither is the default. What decides it is **how much it costs to add later**, weighed against **the evidence that the need is coming**.

## Weigh four things

1. **Cost to add it later.** Count everything that has to change, not just the code: stored data (a migration), outside consumers (partners, other teams, a CSV, webhook, or API contract), and every caller. Internal code with few callers is cheap. A persisted shape or a published contract is expensive.
2. **Evidence the need is coming.** A ticket, a line in the spec, a second caller in progress, an open PR. "Might", "eventually", or a passing mention is not evidence.
3. **Cost of building it now.** The extra code, files, or packages that every reader pays for.
4. **Cost of guessing the shape wrong.** A shape guessed from one case is usually wrong. You carry it, and rewrite it anyway.

Then look for **cheap insurance**: the smallest step that keeps the door open without building the feature. An array instead of a single value, a version field, an enum instead of a boolean, the logic kept in one module so it can move later. It is often the answer.

## Every fork comes out as one of two shapes

| Situation | Shape |
|---|---|
| Cheap to add later | **Decide**: build only what's needed |
| Expensive to add later, and the need is evidenced | **Decide**: build the smallest seam or insurance |
| Anything else | **Weigh**, then wait for the user's pick |

**Decide** is one line: what you built, and what adding the rest later would cost. It ends without a question.

```
Kept it to `rowsToCsv()`. Adding PDF later means wrapping one function, and there's no ticket for it yet.
```

**Weigh** gives every option both its pros and its cons, in concrete terms: files, migrations, who is affected.

```
**Fork:** notes collection — `author: {…}` or `authors: [{…}]`?
(a) `author` (what the ticket needs). Pros: matches the ticket; readers stay simple. Cons: co-authors later means migrating every stored note and updating every reader.
(b) `authors` (for co-authors). Pros: no migration if co-authors arrive. Cons: every reader handles a list that always has one item; nothing scheduled asks for co-authors.
(c) Cheap insurance: `author` plus a `schemaVersion` field. Pros: a later migration can run lazily, note by note. Cons: the migration and the reader changes still happen.
**Tips it:** whether co-authoring is on the roadmap at all.
**Lean:** (b), because notes are written in production from day one, and migrating stored data is the expensive side.
```

Leave out (c) when there is no real insurance step.

## Common mistakes

- **A one-sided pitch with an opt-out.** Reasons for your pick only, then "or do you want the package now?" or "tell me if you'd rather". The user can't choose without the other side's case. If the trade-off is lopsided, decide. If it isn't, weigh both sides.
- **Counting only the code.** "Adding a value is a one-line change" is wrong once that value lands in a CSV a partner imports, or in stored documents.
- **A mention driving the design.** "Contacts will want this too" with no ticket is a guess. If it shapes a name, a package boundary, or an input type, surface it as a fork.
- **"More flexible" as a pro.** Name the case the flexibility serves, or drop it.
- **Asking whether the need will happen at all.** That's a product question. Use **spotting-product-decisions** to find its owner.
