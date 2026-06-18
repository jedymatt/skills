---
name: coding-principles
description: Use when writing, modifying, refactoring, or reviewing code — especially when about to extract duplicated logic, add a parameter to an existing function, pass a true/false argument, inline a numeric literal, write an explanatory comment, or reach through an object's internals.
---

# Coding Principles

Personal defaults for code-quality judgment, in any language. Scope: **only code being written or modified in the current task** — never drive-by refactor untouched code; mention findings instead.

## Quick reference

| Situation | Rule |
|---|---|
| Logic duplicated 2× | Leave it WET — don't extract, don't request extraction in review |
| Same logic appears a 3rd time | Extract now (Rule of Three / DRY) |
| Writing or growing a function with SRP signs (below) | Split into named phase functions |
| Tempted to add a boolean param | Split or enum/union (see below) |
| 4+ positional params | Options object / keyword args, or rethink the design |
| Meaningful inline literal | Named constant (`RETRY_DELAY_MS = 500`) |
| Calling behavior through a property chain | Accept the collaborator directly |
| Tempted to write a comment | Rename/restructure until it's unneeded; comment only the naturally-complex why |

## Rule of Three

Two occurrences are not enough evidence to pick the right abstraction; a wrong abstraction costs more to unwind than duplication. "They'll drift apart" is not a reason at 2× — if they drift, they were never the same thing. The third occurrence proves the shape: extract then.

## Single responsibility

A function does one job, stateable in one sentence without "and". "Too long" is judged by signs, not a line count:

- Section comments staging the body into phases (`# --- validate ---`, `# --- format ---`)
- A name that under-sells the body (`build_report` that also fetches and validates)
- No one-sentence summary possible

Split when you're writing a function that would show these signs — or when your change **grows** one that already does (adds or extends a phase): the new logic lands as its own named phase function, never inlined as another stage of the monolith. A small landing (a line or two) in a staged function doesn't obligate decomposing it — flag the smell instead of fixing it uninvited. Exception: mechanical migrations told to mirror existing structure.

## Boolean parameters

A new boolean flag parameter means the function grew a second behavior — an SRP violation. Decide case by case:

- Behaviors diverge meaningfully (different flow, retries, output) → **two named functions** sharing a private helper:

  ```
  # NOT: send_mail(mail, transport, urgent=false)
  send_urgent_mail(mail, transport):
      deliver(with_subject_prefix(mail, URGENT_PREFIX), transport, URGENT_RETRY)
  ```

- One job with a small self-documenting variation → **enum/union param**: `align: LEFT | RIGHT`, never `right_align: bool`.
- Booleans as *data* in an options object (`include_voided`) are fine — the rule targets control-flow flags.

## Arguments

Max 3 positional parameters — **every function, including private helpers you extract**. A 4th — even optional/defaulted (`attempts=3, delay_ms=500`) — means bundling params that travel together (`retry: RetryPolicy`) or an options object / keyword args; call sites must never read `fn(a, b, 5, 250)`. Count before writing the helper: `deliver(channel, recipient, retry, log, attempt)` is already over. Don't widen a public signature just to reuse its body — extract a private helper and keep the public API narrow.

## Magic numbers

Name every meaningful literal: `MAX_ATTEMPTS = 3`, not `attempt <= 3`. Exempt: 0, 1, -1 in obvious idioms. "Minimal diff" doesn't excuse inline literals on lines already being touched.

## Coupling

Depend on the narrowest thing that works.

- **Take what you use.** Don't accept a whole object to read one or two fields — `send_receipt(email, …)`, not `send_receipt(account)` reading `account.profile.contact.email`. Framework-imposed signatures (ctx/request handlers) are exempt, and entry points may accept the domain object the caller naturally holds — narrow it immediately and pass pieces onward.
- **Don't reach through.** Calling behavior at the end of a property chain (`account.billing.gateway.client.charge(…)`) couples you to every link — accept the collaborator (the `client`, or a `charge` capability) instead. Reading fields off plain data shapes is fine.

## Self-explanatory code

Naming does the explaining — a comment is a fallback, not a habit:

- Name variables and functions so no comment is needed: `days_until_cutoff`, not `d` plus a comment.
- A comment that paraphrases the adjacent code or name gets deleted (`# truncate the subject` above `truncate_subject`).
- Doc-banners and section markers aren't documentation — they're the SRP sign above.
- Naturally complex logic (domain quirk, non-obvious invariant, why-not-the-obvious-way) gets a comment when genuinely needed — explaining **why**, not what.

Any helper you extract must itself obey every rule above — no `format_line(id, amount, date, compact, fmt)`.

## Rationalizations

| Excuse | Reality |
|---|---|
| "Duplicates will drift out of sync" | At 2× you can't see the true shape yet. Wait for the third. |
| "Defaulted params are the smallest diff" | And bare `5, 250` at every call site forever. |
| "Constants can come in a follow-up" | They never do. Same commit. |
| "It's basically the same function" | Then occurrence #3 will prove it. |
| "Splitting it bloats the diff" | You're already modifying it — named phases review easier than a longer monolith. |

## Red flags

- Bare `true`/`false` or naked number in a call expression
- A signature crossing 4 params ("just one more")
- Review comment demanding extraction of code that appears only twice
- Growing a new phase inside an already-staged function instead of splitting it
- A method call at the end of an `a.b.c.d` chain
- A comment that paraphrases the adjacent name or code
- Refactoring functions your task didn't touch
