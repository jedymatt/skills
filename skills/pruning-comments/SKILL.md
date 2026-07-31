---
name: pruning-comments
description: Use when cleaning up comments in code — a file, diff, or PR carries comments that restate the line below, paraphrase a function name, echo the signature in `@param`/`@returns`, banner a section, or preserve commented-out code and changelog notes; when a comment contradicts the code it sits above; or when the ask is to remove unnecessary, redundant, obvious, or self-explanatory comments and tighten the ones worth keeping. A cleanup pass over comments that already exist — not write-time judgment on a comment you're about to add (coding-principles), and not a general design audit (detecting-code-smells).
---

# Pruning Comments

## Overview

Go through the comments that are already there, delete the ones carrying no information, and shorten the rest. Prune, don't strip: the goal is fewer lines to read, not zero comments.

**A comment earns its place by saying something the code cannot.** The code already says what it does and how. A comment is for the why, the constraint, and the context that lives outside the file.

Pairs with **coding-principles** (don't write the comment in the first place) and **detecting-code-smells** (spot the redundant comment during review). This skill is the pass where you actually cut.

## Process

1. **Scope it** — only the files or the diff in front of you. A comment pass is not a repo sweep.
2. **Check the never-touch list** before deleting anything.
3. **Run the keep test** on every remaining comment.
4. **Shorten what survives.**
5. If the fix is a rename, that's a code change — make it deliberately and re-run types and tests.

## Never touch

These look like comments but are load-bearing. Deleting them breaks the build or loses a contract.

- Pragmas and directives — `// eslint-disable-next-line`, `// @ts-expect-error`, `// oxlint-disable`, `// prettier-ignore`, `// biome-ignore`, `# type: ignore`, `# noqa`
- Licence and copyright headers
- Codegen markers — `// AUTO-GENERATED — do not edit`, region markers a tool rewrites
- `TODO` / `FIXME` — that's recorded intent, not noise. Cut only when the thing is demonstrably done.
- Docstrings on a package's public API that a doc site or IDE surfaces
- Tooling hints — `/** @type {…} */` in JS, i18n extraction comments, shebangs

## The keep test

Run it on each comment, in order.

0. **Is it still true?** A comment that contradicts the code is the most expensive kind. Find out which side is wrong before touching either — a drifted comment often marks a real bug.
1. **Delete it and read the code.** Nothing lost? It stays deleted.
2. **Something lost — can a name carry it?** Rename the variable, function, or constant so the meaning lands in the code, then delete the comment.
3. **Still lost?** It's a real comment. Keep it, and make it one line.

## Delete on sight

| Comment | Why it goes |
|---|---|
| Restates the line — `// increment retries` over `retries++` | The code said it |
| Paraphrases the name — `// send the receipt` over `sendReceipt(…)` | The name said it |
| `@param userId The user id`, `@returns the result` | Echoes the signature; the type is the doc |
| Section banner — `// --- validation ---` | Not documentation — it's an SRP sign. Extract the phase instead (coding-principles) |
| Commented-out code | Git has it |
| Changelog or attribution — `// added by X, 2026-01-02`, `// changed in #123` | `git blame` has it |
| Ticket narrative the code already implements — `// per ABC-123 we now skip drafts` above `if (isDraft) return` | Keep the constraint if there is one; drop the story |
| Tutorial narration — `// loop through users`, `// import the client` | Teaches the language, not the code |
| Boilerplate docblock on an internal function, restating its name | Template noise; docblocks are for published APIs |
| Divider rules and ASCII art | Formatting, not information |
| A comment that contradicts the code | Wrong is worse than absent — resolve it, then delete or fix |

## Worth keeping

| Comment | Why it earns the line |
|---|---|
| The why behind a non-obvious choice | Can't be derived from the code |
| Why *not* the obvious way — a rejected alternative, a workaround for an upstream bug (with a link) | Stops the next reader from "fixing" it back |
| A constraint the types can't state — ordering, locking, an invariant callers must hold | A real contract, invisible in the signature |
| A domain or regulatory rule that isn't derivable | "Lenders require three years of history" |
| A pointer outside the file — `See <path>`, a spec or issue link | Context the file can't hold |
| A landmine warning — "don't reorder; the next call depends on this side effect" | Prevents a plausible, breaking edit |
| One example for dense syntax — what a regex matches, what a bit mask means | Cheaper than decoding it on every read |
| Published API docs a generator or consumer reads | A contract, not a restatement |

## Rewriting what stays

- **One line.** Two at most. A paragraph is still too long.
- **No labels.** Never prefix `What:` / `Why:` / `Note:` — say the thing in plain prose.
- **No preamble.** Cut "This function is responsible for…", "Basically…", "Note that…" and start at the point.
- **Give the reason, not the mechanism.** The code has the mechanism.
- **Match the file.** Don't upgrade a `//` to a `/** */` block, and don't add comments the surrounding code doesn't have.

## Example

```ts
// NOT — five comments, none of them information
/**
 * Formats a liability for the PDF.
 * @param liability The liability
 * @returns The formatted string
 */
// added by jed 2026-01-14 (ABC-123)
function formatLiability(liability: Liability): string {
  // --- normalise ---
  // convert the repayment to monthly
  const monthly = liability.repayment * FREQUENCY[liability.frequency];
  // return the formatted string
  return `${liability.name} — ${fmtCurrency(monthly)}`;
}
```

```ts
// pruned — one line, saying the thing the code can't
function formatLiability(liability: Liability): string {
  // Providers send an already-monthly figure and no frequency, so FREQUENCY maps undefined to 1.
  const monthly = liability.repayment * FREQUENCY[liability.frequency];
  return `${liability.name} — ${fmtCurrency(monthly)}`;
}
```

## Rationalizations

| Excuse | Reality |
|---|---|
| "It's harmless, leave it" | Every comment gets read and re-verified forever. A stale one misleads. |
| "It might help a junior" | A good name helps everyone. A restatement helps no one. |
| "The docblock documents the parameter" | The type documents the type. State the constraint or delete. |
| "Keep the commented-out code just in case" | Git has it. Delete. |
| "Every exported function should have a docblock" | Only if something publishes it. Otherwise it's a template with no content. |
| "I'll add a why so it can stay" | If you have to invent the why, there wasn't one. |
| "Deleting comments looks like I did nothing" | Fewer lines to read is the deliverable. |
| "The comment is wrong but the code works" | Then it's a trap for the next reader. Fix it or cut it. |

## Red flags

- A comment that paraphrases the line directly below it
- `@param` / `@returns` echoing the name and type
- `// --- section ---` banners inside a function body
- Commented-out code, dates, names, or ticket numbers used as a changelog
- A comment longer than the code it describes
- The comment says X and the code does Y
- A `/** */` block on a one-line internal helper

## Common mistakes

- **Deleting a pragma** because it looks like a comment — breaks the build or the lint gate.
- **Sweeping files the task didn't touch.** Same scope rule as coding-principles.
- **Keeping a comment by inventing a why for it.**
- **Replacing three bad comments with one long good one.** Still too long.
- **Cutting the only record of a bug workaround.** If a comment looks odd but specific, check `git blame` or the linked issue before deleting.
