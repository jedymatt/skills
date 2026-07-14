---
name: coding-principles
description: Use when writing or changing code and second-guessing whether a choice is clean — the "is this fine?", "does this smell?", "leave it inline or refactor?", "how do I split this?" moments mid-coding. Covers per-function and per-file calls like a magic number or delay instead of a named constant; a boolean flag or 4th parameter; abstraction/config "for later"; a function growing long or mixing levels; reaching through an a.b.c.d chain; duplicating a block; a comment a better name would replace. Write-time judgment on code you're touching now — not auditing existing code for smells (detecting-code-smells), nor module/layer structure (architecting-principles).
---

# Coding Principles

Personal defaults for code-quality judgment, in any language. Scope: **only code being written or modified in the current task** — never drive-by refactor untouched code; mention findings instead.

## Quick reference

| Situation | Rule |
|---|---|
| Logic duplicated 2× | Leave it WET — don't extract, don't request extraction in review |
| Same logic appears a 3rd time | Extract now (Rule of Three / DRY) |
| About to add abstraction/config/a param "for later" | Don't — build only what the task needs now (YAGNI) |
| Writing or growing a function with SRP signs (below) | Split into named phase functions |
| A function mixing high-level intent with low-level mechanics | Lift the detail into a named helper — one altitude per function |
| Wrapping a function body in `if (ok) { … }` | Guard clause — bail early on the negative, keep the happy path flat |
| Writing a loop nested inside another, esp. 3+ deep | Extract the inner loop into a named function — each level stays one job |
| Writing a condition that negates a negative (`!is_invalid`, `not disabled`) | Flip to a positive predicate; one negative is the limit |
| Writing a condition you have to decode (multi-clause, nested ternary) | Bind it to a named predicate (`can_post = …`) |
| Tempted to add a boolean param | Split or enum/union (see below) |
| 4+ positional params | Options object / keyword args, or rethink the design |
| Meaningful inline literal | Named constant (`RETRY_DELAY_MS = 500`) |
| Hoisting locals to the top, or reusing one variable for two meanings | Declare at first use; one variable, one meaning |
| Calling behavior through a property chain | Accept the collaborator directly |
| A `get_`/`is_` query that also mutates, or a command you read a value from | Split: queries return and don't change; commands change and don't return |
| Naming a function or a variable | Function/method = verb phrase (`send_receipt`); variable/field/param = noun phrase (`days_until_cutoff`); boolean = predicate (`is_active`) |
| The same concept under several names (`get`/`fetch`/`load`) | One word per concept, one concept per word |
| Tempted to write a comment | Rename/restructure until it's unneeded; comment only the naturally-complex why |
| Reaching for a clever one-liner or trick | Write the obvious version; decode time costs more than length |
| A conditional wedged mid-expression (`experience${n === 1 ? '' : 's'}`) | Lift the branch to the top; give each side a whole, readable value |

## Rule of Three

Two occurrences are not enough evidence to pick the right abstraction; a wrong abstraction costs more to unwind than duplication. "They'll drift apart" is not a reason at 2× — if they drift, they were never the same thing. The third occurrence proves the shape: extract then.

## Don't over-engineer

Build for the requirement in front of you, not an imagined future (YAGNI). Speculative generality costs now for a need that may never arrive — and is usually guessed wrong.

- No abstraction, interface, config flag, or extension point until a *second real* caller needs it (Rule of Three again).
- No parameters or hooks for cases the task doesn't have; delete "just in case" options.
- Prefer the direct solution — a function over a framework, a literal over a config system, a plain call over an indirection layer.
- One concrete implementation beats a configurable engine with a single user.

Solving a more general problem than asked is scope creep — flag the future need instead of building for it.

## Single responsibility

A function does one job, stateable in one sentence without "and". "Too long" is judged by signs, not a line count:

- Section comments staging the body into phases (`# --- validate ---`, `# --- format ---`)
- A name that under-sells the body (`build_report` that also fetches and validates)
- No one-sentence summary possible

Split when you're writing a function that would show these signs — or when your change **grows** one that already does (adds or extends a phase): the new logic lands as its own named phase function, never inlined as another stage of the monolith. A small landing (a line or two) in a staged function doesn't obligate decomposing it — flag the smell instead of fixing it uninvited. Exception: mechanical migrations told to mirror existing structure.

## One level of abstraction

Within a function, keep every step at the same altitude. Mixing a high-level decision (`if order.is_eligible`) with low-level mechanics (byte juggling, index math, raw SQL) in one body makes the reader change zoom on every line. Lift the low-level work behind a named helper so the function reads as one consistent story.

- **Read it as a sentence.** Each line sits at one conceptual level — orchestrate calls, *or* do the fiddly work, not both interleaved.
- **A name drops the reader down a level.** `notify(customer)` hides the SMTP and retry detail; the caller stays at intent. Push detail behind a name instead of inlining it.
- **Distinct from single responsibility.** SRP asks *how many jobs* (one); this asks *how many altitudes* within that job (one). A function can do a single job yet still mix levels — extract the levels.
- **Don't over-apply.** A one-line low-level touch inside a high-level function isn't a violation — extract when the altitude clash spans several lines or recurs.

```
# NOT — intent and byte-level detail interleaved
def export_invoice(invoice):
    if not invoice.is_final: raise NotFinal
    record = invoice.id.rjust(8, "0") + "|" + f"{invoice.total:.2f}"
    upload(record)

# one altitude — the detail is named and a level down
def export_invoice(invoice):
    if not invoice.is_final: raise NotFinal
    upload(to_record(invoice))

def to_record(invoice):
    return invoice.id.rjust(8, "0") + "|" + f"{invoice.total:.2f}"
```

## Early return

Handle preconditions, edge cases, and error paths first — return or throw immediately so the main logic stays at the base indentation. The happy path reads top-to-bottom, never buried inside nested `if`s.

- **Guard clause over nesting.** `if not valid: return` then continue, instead of wrapping the whole body in `if valid: { … }`.
- **No `else` after a `return`.** The fallthrough already *is* the else — dedent it; an `else` branch following a return is dead structure.
- **One bail per guard, named once at the top.** Each guard states a single reason to stop, before the work begins.
- **Don't over-apply.** A handful of sequential guards is clarity; returns scattered through deep logic is a function doing too much — split it (single responsibility), not paper over it with more returns.

```
# NOT — arrow code, happy path buried
def charge(order):
    if order.is_valid:
        if order.has_funds:
            capture(order)
        else:
            raise NoFunds
    else:
        raise Invalid

# guard clauses — flat happy path
def charge(order):
    if not order.is_valid: raise Invalid
    if not order.has_funds: raise NoFunds
    capture(order)
```

## Nested loops

A loop nested inside another loop does two jobs — driving the outer collection *and* the inner work. Past two levels the body stops reading top-to-bottom and you track several index variables at once. Extract the inner loop into a named function so each level reads as one job.

- **Extract the inner loop as named work**, not just its body: the outer loop calls `total_team(team)`; the helper owns `for member in team.members: …`.
- **Two genuine dimensions can stay** when the shape is truly 2-D (a grid, a matrix) and the body is a line or two — a hop would only add noise. Three levels is the smell, always.
- **Don't over-apply.** A short, flat inner loop that reads clearly isn't a violation — flag it at most. The trigger is depth *plus* a body you can't summarize in one phrase.

```
# NOT — three levels, every index live at once
def total_company(departments):
    grand = 0
    for dept in departments:
        for team in dept.teams:
            for member in team.members:
                grand += member.hours
    return grand

# extract each inner loop as named per-item work
def total_company(departments):
    return sum(total_department(dept) for dept in departments)

def total_department(dept):
    return sum(total_team(team) for team in dept.teams)

def total_team(team):
    return sum(member.hours for member in team.members)
```

## Double negatives

A condition should read as a positive assertion. Negating a negative — a `not` over an already-negative name (`!is_invalid`, `not is_not_verified`, `!disabled`), or two negatives in one expression — forces the reader to flip the meaning, often twice, before knowing what's true.

- **Name the positive predicate.** Define `is_valid`, not `is_invalid`; `enabled`, not `disabled`. Then `if not is_valid` reads in one pass and `if is_valid` needs none. The naming rule below makes it a predicate; this keeps the predicate positive.
- **Positivize compound conditions.** Apply De Morgan: `!(!a || !b)` → `a && b`; `not (not found or empty)` → `found and not empty`. Push the negation inward until each term is stated positively.
- **One negative is the limit.** A single `not` is clear — a guard clause `if not is_valid: return` reads once. The smell is the *second* flip, not the first.
- **Don't over-apply.** A genuinely negative domain term stays (`if not is_expired` is one honest negative); don't invent a positive antonym nobody uses just to dodge a `not`.

```
# NOT — negates a negative, reader flips twice
if not user.is_not_verified:
    grant_access()

# positive predicate, reads once
if user.is_verified:
    grant_access()
```

## Name complex conditions

When a condition takes more than a glance to parse — several `and`/`or` terms, a comparison buried in a chain, a ternary inside a ternary — bind it to a named predicate. The reader then checks one intention-revealing name instead of re-deriving the logic each read.

- **One predicate, one name.** `eligible_for_refund = order.paid and not order.shipped and within_window(order)`, then `if eligible_for_refund:`.
- **No nested ternaries.** A ternary whose branches are themselves ternaries is write-only — expand it to named booleans or an `if`/`elif` ladder.
- **The name states intent, not mechanics.** `is_quorum`, not `count_ge_half` — the reader wants *what it decides*, not how.
- **Don't over-apply.** A single comparison (`if age >= 18`) is already clear; naming it `is_adult` is fine but not required. The trigger is a condition you have to *decode*, not merely read.

```
# NOT — three clauses to decode at the branch
if user.age >= 18 and not user.banned and user.email_verified:
    allow_post()

# named predicate — the branch reads as intent
can_post = user.age >= 18 and not user.banned and user.email_verified
if can_post:
    allow_post()
```

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

## Variable scope

Declare a variable as late as possible — right before its first use — and let it die once it's done. The fewer lines a value is *live*, the fewer things the reader holds in working memory at once.

- **Late declaration.** Don't hoist a block of `let`s to the top of a function; introduce each where it's first needed, beside the code that gives it meaning.
- **One variable, one meaning.** Never repurpose a `tmp`/`result`/`i` for a second, unrelated value — a name whose meaning changes mid-function is something the reader must re-learn. Use a fresh name.
- **Narrow the live range.** A value used only inside one branch or loop is declared there, not in the enclosing scope.
- **Don't over-apply.** A value genuinely used across the whole function belongs up top; this isn't a mandate to cram everything into one expression.

```
# NOT — hoisted, and `total` repurposed mid-function
def summarize(orders):
    total = 0
    result = None
    for o in orders: total += o.amount
    result = total / len(orders)
    total = max(o.amount for o in orders)   # `total` now means something else
    return result, total

# each value introduced at first use, one meaning each
def summarize(orders):
    amounts = [o.amount for o in orders]
    average = sum(amounts) / len(amounts)
    largest = max(amounts)
    return average, largest
```

## Coupling

Depend on the narrowest thing that works.

- **Take what you use.** Don't accept a whole object to read one or two fields — `send_receipt(email, …)`, not `send_receipt(account)` reading `account.profile.contact.email`. Framework-imposed signatures (ctx/request handlers) are exempt, and entry points may accept the domain object the caller naturally holds — narrow it immediately and pass pieces onward.
- **Don't reach through.** Calling behavior at the end of a property chain (`account.billing.gateway.client.charge(…)`) couples you to every link — accept the collaborator (the `client`, or a `charge` capability) instead. Reading fields off plain data shapes is fine.

## Command–query separation

A function either **does** something or **answers** something — never both. A query returns a value and leaves the world unchanged; a command changes state and returns nothing to read. Mixing them means a caller can't ask a question without triggering a side effect, and can't tell from the call site that asking has a cost.

- **Queries stay pure to the caller.** `get_balance()`, `is_ready()`, `current_id()` must not mutate, advance, or lazily create. If `get_X` changes X, rename it or split it.
- **Commands return nothing to read.** `save()`, `enqueue(job)`, `retry()` act; don't smuggle a queried value out of them — fetch it with a separate query.
- **No surprise on a getter.** The reader assumes an `is_`/`get_`/noun-ish call is free of consequences. Honour that so they needn't read the body to stay safe.
- **Don't over-apply.** Idiomatic mutating reads stand by contract: `stack.pop()`, `cache.get_or_compute(k)`, an iterator's `next()`.

```
# NOT — a query that also mutates
def next_ticket(self):
    self.counter += 1      # command hidden inside a query
    return self.counter

# split: command changes, query answers
def advance(self):         # command — returns nothing
    self.counter += 1

def current_ticket(self):  # query — no side effect
    return self.counter
```

## Self-explanatory code

Naming does the explaining — a comment is a fallback, not a habit:

- **Name by part of speech.** A function or method is a *verb phrase* — it does something: `calculate_total`, `send_receipt`, `parse_header`, never `total()` or `receipt()`. A variable, field, or parameter is a *noun phrase* — it holds something: `days_until_cutoff`, `pending_orders`, never `calculate` or `done`. A boolean reads as a *predicate*: `is_active`, `has_balance`, `can_retry`.
- Name variables and functions so no comment is needed: `days_until_cutoff`, not `d` plus a comment.
- A comment that paraphrases the adjacent code or name gets deleted (`# truncate the subject` above `truncate_subject`).
- Doc-banners and section markers aren't documentation — they're the SRP sign above.
- Naturally complex logic (domain quirk, non-obvious invariant, why-not-the-obvious-way) gets a comment when genuinely needed — explaining **why**, not what.

Any helper you extract must itself obey every rule above — no `format_line(id, amount, date, compact, fmt)`.

## One name per concept

Use the same word for the same idea everywhere, and a different word only for a different idea. If `fetch`, `get`, and `load` all mean "read from the store" across the code, the reader keeps asking whether the difference is meaningful — consistency lets them stop wondering.

- **One verb per operation.** Pick `fetch_*` for remote reads and use it throughout; don't scatter `get_`/`load_`/`retrieve_` for the identical action.
- **One noun per thing.** The same concept stays `customer` everywhere — not `customer` here, `client` there, `user` elsewhere — unless they are genuinely distinct.
- **Different word ⇒ different meaning.** The flip side: don't reuse one word for two ideas (`account` as both login and ledger). A shared word implies a shared concept that isn't there.
- **Symmetry shows.** Parallel operations read in parallel — `open`/`close`, `start`/`stop`, not `open`/`finish`. A mismatched pair makes the reader check whether the asymmetry means something.

```
# NOT — one operation under three verbs
fetch_user(id); get_order(id); load_invoice(id)

# one verb for the one operation
fetch_user(id); fetch_order(id); fetch_invoice(id)
```

## Prefer obvious over clever

Code is read far more often than written; optimize for the next reader, not for brevity or cleverness. A packed one-liner that has to be mentally executed costs more than the plain version it replaces. Spell out the steps.

- **No write-only tricks.** A comprehension nested in a comprehension, bit-twiddling standing in for arithmetic, chained ternaries, leaning on truthiness quirks — if it must be decoded, expand it.
- **Branch around the whole expression, not inside it.** A conditional spliced into a larger expression — a template string, a function argument, an object literal, an arithmetic term — forces the reader to stop mid-expression and resolve it before they can read the rest as a whole. Lift the branch out so each side is one complete value. Repeating the surrounding expression is cheaper to read than a fragment stitched around an inline `? :`.
- **Obvious beats short.** A few clear lines with a named intermediate beat one dense expression. Line count isn't the cost; decode time is.
- **Clever needs a why.** If a non-obvious form is genuinely required (a measured hot path, a real constraint), keep it *and* comment the reason — the exception, not the habit.
- **Don't over-apply.** Idiomatic, widely-read constructs aren't "clever": a list comprehension, a ternary for a simple default, ordinary standard-library use. The target is code that hides intent, not every concise expression.

```
# NOT — clever; must be run in your head
return [x for s in data for x in (s or [])][::-1][:k]

# obvious — each step named
flattened = [x for s in data for x in (s or [])]
newest_first = list(reversed(flattened))
return newest_first[:k]
```

```
// NOT — a ternary wedged mid-expression; the reader halts to resolve it
`Seeded ${n} experience${n === 1 ? '' : 's'} into ${org}`

// branch around the whole value — each side reads straight through
n === 1
  ? `Seeded ${n} experience into ${org}`
  : `Seeded ${n} experiences into ${org}`
```

## Rationalizations

| Excuse | Reality |
|---|---|
| "Duplicates will drift out of sync" | At 2× you can't see the true shape yet. Wait for the third. |
| "Defaulted params are the smallest diff" | And bare `5, 250` at every call site forever. |
| "Constants can come in a follow-up" | They never do. Same commit. |
| "It's basically the same function" | Then occurrence #3 will prove it. |
| "Splitting it bloats the diff" | You're already modifying it — named phases review easier than a longer monolith. |
| "We'll need this flexibility later" | Usually you won't, or you'll guess wrong. Add it when the need is real. |
| "Single exit is cleaner" | One return buried in nested `if`s reads worse than guards that bail early up front. |
| "It's just iterating, nesting is natural" | Past two levels you track every index at once. Extract the inner loop. |
| "`not is_not_done` is clear enough" | It's two flips to read. Name the positive predicate. |
| "It's all one function's job" | One job can still mix altitudes. Name the low-level step and drop a level. |
| "The condition is right there, inline" | Right there and re-decoded every read. Name the predicate once. |
| "Returning the value from the setter saves a call" | Now no one can read it without mutating. Split query from command. |
| "Declaring everything up top is tidy" | It widens every variable's live range. Introduce each at first use. |
| "Get and fetch are basically synonyms" | Then the reader keeps checking if you meant a difference. Pick one. |
| "The one-liner is more elegant" | Elegant to write, slow to read. Optimize for the next reader. |
| "The inline ternary only changes one word" | The reader still halts mid-expression to prove that. Branch around the whole value. |

## Red flags

- Bare `true`/`false` or naked number in a call expression
- A signature crossing 4 params ("just one more")
- Review comment demanding extraction of code that appears only twice
- Growing a new phase inside an already-staged function instead of splitting it
- A function body that swings between orchestration and byte/index/SQL-level detail line to line
- An `if` wrapping a whole function body, or an `else` immediately after a `return`
- Three or more loops nested directly inside one another, or a loop body you can't summarize without "for each … and for each …"
- A condition negating a negative — `not`/`!` over an `is_not_…`/`un…`/`dis…` name, or two negatives in one boolean expression
- A multi-clause boolean or nested ternary evaluated inline in an `if`/`while`/`?:` instead of a named predicate
- A method call at the end of an `a.b.c.d` chain
- A `get_`/`is_`-named function with a side effect, or a value smuggled out of a state-changing command
- Locals declared far above first use, or a `tmp`/`result` reassigned to an unrelated second meaning
- The same operation or thing under several names (`get`/`fetch`/`load`), or one word covering two unrelated concepts
- A packed expression (nested comprehension, chained ternary, bit-twiddle) that must be mentally executed to understand
- A conditional interpolated inside a string or larger expression (`` `…${n === 1 ? '' : 's'}…` ``) instead of branching around the whole value
- A function named as a noun (`total()`), a variable named as a verb (`calculate`), or a boolean that isn't a predicate
- A comment that paraphrases the adjacent name or code
- Refactoring functions your task didn't touch
- An abstraction, config knob, or parameter whose only caller is hypothetical
