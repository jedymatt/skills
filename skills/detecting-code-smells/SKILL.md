---
name: detecting-code-smells
description: Use when reviewing or auditing existing code for quality problems — finding, checking, or detecting code smells in a file, diff, or PR; judging whether code is "smelly"; or producing a findings list of design and readability issues before merge. For review-time detection, not write-time judgment (see coding-principles), and not auto-fixing.
---

# Detecting Code Smells

## Overview

Find design and readability problems in existing code and report them as a **findings list** — location, what's wrong, severity, and the fix direction. Detect and recommend; don't rewrite unless asked.

A smell is a *design* signal (hard to change, hard to read, easy to break), **not** a style or formatting nit — leave those to the linter.

Pairs with **coding-principles**: that skill is write-time judgment, this one is review-time detection. The catalog cross-references it instead of repeating it.

## Process

1. **Set scope** — the file, diff, or PR named. Nothing else.
2. **Scan each unit** (function, class, module) against the catalog.
3. **Record each hit:** location, smell, one-line why, severity, fix direction.
4. **Skip non-smells** — working code with a clear style choice, framework-imposed shapes, intentional 2× duplication. Don't manufacture findings to look thorough.
5. **Report** by severity, highest first, with a one-line count summary.

## Smell Catalog

Several map to **coding-principles** — for those, the fix lives there.

| Smell | How to spot it | Fix direction |
|---|---|---|
| God function (low cohesion) | Body splits into phases; name undersells it; no one-sentence summary | Named phase functions — coding-principles |
| Mixed abstraction levels | A function interleaves high-level intent and low-level mechanics | Lift the detail into a named helper — coding-principles |
| Control-flag parameter | A `bool` that switches behavior | Two functions or an enum — coding-principles |
| Long parameter list | 4+ positional params | Options object / bundle params that travel together — coding-principles |
| Magic number | Bare meaningful literal in an expression | Named constant — coding-principles |
| Message chain / train wreck | Calls at the end of `a.b.c.d` | Accept the collaborator directly — coding-principles |
| Premature abstraction | Layer/config/param with one or hypothetical caller | Inline it; wait for a real need — coding-principles |
| Premature DRY | Extraction of logic seen only twice | Leave WET until the 3rd use — coding-principles |
| Redundant comment | Comment paraphrases the adjacent name/code | Delete it; rename instead — coding-principles |
| Long method | Many lines / responsibilities regardless of phases | Extract sub-steps |
| Large class / god object | One type holds many unrelated jobs or fields | Split by responsibility |
| Feature envy | A method uses another object's data more than its own | Move the method to that object |
| Primitive obsession | Bare strings/ints/maps where a small type belongs | Introduce a value type |
| Data clumps | The same group of fields/args travels together everywhere | Bundle into one type |
| Shotgun surgery | One logical change forces edits across many files | Gather the responsibility into one place |
| Divergent change | One module changes for many unrelated reasons | Split along the axes of change |
| Dead code | Unreached branches, unused functions/vars | Delete it |
| Inappropriate intimacy | Two units reach into each other's internals | Define a narrow interface between them |
| Mysterious name | `d`, `tmp`, `handle2`, or a name that misleads | Rename to what it is |
| Part-of-speech mismatch | Function named as a noun, variable as a verb, boolean not a predicate | Verb for functions, noun for variables, predicate for booleans — coding-principles |
| Double negative | A condition negates a negative name (`!is_invalid`) or stacks two negatives | Positive predicate; De Morgan — coding-principles |
| Deep nesting | Arrow-shaped conditionals 3+ levels deep | Early returns / guard clauses; extract — coding-principles |
| Nested loops | Loops 3+ levels deep / a body that drives two collections at once | Extract the inner loop into a named function — coding-principles |

## Findings Format

```
- `src/mailer.py:42` — **God function** (high): send_report fetches, validates, formats, and sends. Split into named phase functions. (coding-principles: single responsibility)
- `src/cart.ts:88` — **Primitive obsession** (medium): passes `currency: string`; a value type stops invalid values.
```

## Severity

- **High** — bug risk, or makes code hard to change / a change spreads (shotgun surgery, god object, train wreck).
- **Medium** — clarity and maintainability (primitive obsession, feature envy, redundant comment).
- **Low** — minor, safe to defer (a slightly long method that still reads clearly).

## Common Mistakes

- **Style nits as smells.** Formatting, import order, quote style → linter's job, not this.
- **Out-of-scope findings.** Don't flag code the review didn't touch (note it briefly at most).
- **Calling 2× duplication a smell.** Two copies isn't a smell yet (Rule of Three) — don't report it.
- **Oversized fixes.** Recommend a proportional change, not a module rewrite.
- **Auto-fixing.** Detect and recommend; apply changes only when asked.
