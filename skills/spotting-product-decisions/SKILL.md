---
name: spotting-product-decisions
description: Use before making a choice the user would notice, or before saying something "can't" be done — to tell a technical limitation (the code decides, so solve it) from a product decision (people decide, so surface it with options). Triggers proactively when about to write "can't", "not possible", "has to", "the only way", or "I'll default to"; when picking what to show, hide, clear, default, order, word, or allow; when deferring, skipping, or folding in scope; when filling a gap the spec or ticket didn't cover; or when a reviewer's comment asks for a behaviour change. Also use when the user asks "is this a product call?", "who should decide this?", "is this a tech limit or a choice?", "should I ask the PM?", or "can we actually not do this?".
---

# Spotting Product Decisions

## Overview

Before you make a call or say "can't", work out **who owns the call**.

- **Technical limitation** — the code, data, API, types, or platform decide. Once you understand them, there's one right answer. Solve it.
- **Product decision** — more than one behaviour is valid, and the choice changes what a user sees, does, or trusts. People decide. Surface it with options. Don't pick quietly.

Why this matters: an agent makes many small choices while coding. Most are technical and fine to make. But some are product choices hiding inside code — a default value, a field left out, a "for now" scope cut. Made silently, they ship without anyone deciding them. The opposite also happens: a product choice gets stated as a technical fact ("we can't show that"), and the user never learns there was a choice.

## The test

Ask three questions about the fork in front of you.

1. **Where does the constraint come from?** Code, schema, types, an API contract, the platform → leans technical. Users, the business, the team's preference, the spec's silence → leans product.
2. **With full understanding of the code, is there one right answer?** Yes → technical. Two or more reasonable answers → product.
3. **Would a user notice which option you picked?** Different screen, data, wording, default, or workflow → product. Same result either way → technical.

| Call | Looks like | What to do |
|---|---|---|
| **Technical limit** | One right answer, set by the code | Solve it. Cite the evidence. |
| **Product decision** | Several valid behaviours, user-visible | Lay out options. Let the owner pick. |
| **Disguised** | Stated as "can't", really means "costs X" | Name the cost. Paying it is a product call. |
| **Mixed** | A real limit that forces a product choice | State the limit as fact, then ask the product question. |

### Disguised — the one to watch

"Can't" is often "won't, unless someone pays for it". Check: would it work with more time, a migration, another endpoint, or a different design? If yes, it isn't a limit. It's a cost, and whether to pay it is a product decision.

> "We can't show the old value because we don't store it."
> → True today. But we could start storing it. Is the old value worth a schema change? That's a product call.

### Don't escalate what the code can answer

The reverse mistake is just as costly. If the answer sits in the code, the docs, or the data, look it up. Don't send it to the user or a PM. "Which enum value does the API expect?" is not a product question. Asking it wastes someone's time and makes the real questions harder to spot.

## Output

Default to **one line per fork**. Most forks are small, and you can take a reversible default and keep going:

```
Product call — drafts in the export? (a) include, with a status column (my default) · (b) placed and refunded only. Owner: PM.
```

Use the **full block** only when the fork blocks the work or is hard to undo (data shape, access, money, anything shipped to users):

```
**Decision:** <the fork, in one line>
**Call:** Technical limit | Product decision | Disguised | Mixed
**Why:** <evidence — file:line, the contract, or what the user would see>
**Next:** <options, owner, lean>
```

- **Technical:** say the fix in a clause and carry on. Don't list technical choices you made unless the user would care.
- **Product / Disguised / Mixed:** 2–3 options. For each one, say **what the user would see**, not how it's built. Name who likely owns it (the user, PM, design, the reviewer). A lean is fine; label it as a lean.

For a blocking fork, stop and wait for the choice before building that part. For the rest, take the most reversible option and say so.

**Batch and rank.** When several forks come up in one task, put them in one short list, blocking ones first. Don't drip them out one at a time. The user should be able to read the list in under a minute. If it's longer than the code, cut it.

**Leave a trail in the code.** Where you took a default on a product fork, add a short marker at that line, e.g. `// TODO(product): soft-deleted rows excluded — confirm`. The question then outlives the chat.

## Examples

**Technical limit**
> Decision: Put the pay cycle (weekly) in the salary field's frequency dropdown?
> Call: Technical limit
> Why: That dropdown is the unit of the amount next to it. "Weekly" beside an annual figure would show a weekly wage of the annual amount.
> Next: Leave the frequency as annual. Keep the pay cycle out of that field.

**Product decision**
> Decision: In the compare view, what happens to fields the org has hidden?
> Call: Product decision
> Why: Both are valid. The user either sees them flagged, or doesn't see them at all.
> Next: (a) Show them with a "hidden" icon, so the user sees everything but knows what the client can't see. (b) Leave them out, so the view matches what the client sees. Owner: PM/design. Lean: (a), since leaving them out hides data the user might rely on.

**Disguised**
> Decision: "We can't pre-fill the start date, the source doesn't have one."
> Call: Disguised
> Why: The source has a "start of year or start date" field. It's ambiguous, not missing.
> Next: (a) Pre-fill it, and note it may be the start of the financial year. (b) Leave it blank. Owner: PM.

**Mixed**
> Decision: Two people edit the same list at once.
> Call: Mixed
> Why: Technical fact: the whole list is saved at once with no version check, so the last save wins. Product question: is that acceptable?
> Next: (a) Accept last-write-wins (rare in practice). (b) Warn when the data changed since load. (c) Add proper merging (bigger change). Owner: PM.

## Common mistakes

- **Deciding in a code comment.** `// default to X for now` is a product decision with no owner. Surface it.
- **Filling a gap with the nearest field.** No `last_edited_by` column, so show the owner instead? That quietly changes what the label means. Say the data isn't there, and offer options.
- **Calling everything product to be safe.** That buries the real decisions. If the code answers it, answer it.
- **Options without consequences.** "Option A: filter in the mapper" means nothing to a PM. Say what the user sees.
- **Picking, then asking.** Asking after it's built makes the user approve a done deal. Ask at the fork.
- **Treating a reviewer's request as settled.** A comment asking for a behaviour change is still a product call. Check that the owner agrees when it changes what users see.
