---
name: architecting-principles
description: Use when designing or changing how code is organized across modules, packages, or components — especially when about to create or edit code that changes structure: add a new module/layer/service, decide where new code lives, introduce a dependency between parts, create a `utils`/`shared`/`common` bucket, wire a module directly to an external system (DB/HTTP/SDK/vendor), split or merge modules, or add a structural boundary for a future need.
---

# Architecting Principles

Personal defaults for architecture-level judgment, in any language. One level above **coding-principles**: that skill governs *inside a function* (params, literals, reaching through `a.b.c`); this one governs *between* modules, packages, and components — where code lives and how the parts depend on each other. Scope: **structural decisions on the code you're writing or changing.** Flag larger restructures as findings; never drive-by re-architect untouched code.

## Quick reference

| Situation | Rule |
|---|---|
| Adding a dependency between two parts | Make it point one way; never close a cycle |
| High-level policy importing a low-level detail (DB, SDK, framework) | Invert it — both depend on an interface the policy owns |
| Deciding where new code goes | Put it where its data and collaborators already live |
| Tempted to drop code in `utils`/`shared`/`common`/`misc` | Name its real home — a module is a responsibility, not a junk drawer |
| A module needs "and" to describe it | Split it along the responsibilities |
| One change forces edits across many modules | Gather that responsibility into one place (shotgun surgery) |
| One module changes for several unrelated reasons | Split along its axes of change (divergent change) |
| Exposing a module to the rest of the system | Publish the narrowest contract; hide internals and concrete types |
| Calling an external system from core logic | Wrap it behind a port; keep the SDK import at the edge |
| Two places writing the same state | Give the state one owner; others go through it |
| Tempted to add a layer/service/package "for later" | Don't — add the boundary when a real seam appears (YAGNI) |

## Dependency direction

- **One way only.** If A depends on B, B must not depend on A — not directly, not through a chain. A cycle makes either side impossible to understand, test, or change alone.
- **Point inward, toward stable policy.** High-level rules (what the system does) must not import low-level details (how/where data is stored or sent). Both depend on an interface the high-level side owns — dependency inversion.
- **Stable must not depend on volatile.** Core domain logic changes rarely; vendor SDKs, frameworks, and I/O change often. Don't let the rarely-changing thing import the often-changing one.

```
# NOT: order_service imports the vendor SDK directly
#   order_service -> stripe.Charge(...)
# Instead: order_service depends on a PaymentGateway interface it owns;
#   a StripeGateway adapter at the edge implements it.
```

## Cohesion & placement

- **New code lives with its data and collaborators.** Put a function near the thing it operates on; scattering related logic raises coupling and hides it.
- **No dumping grounds.** `utils`, `helpers`, `shared`, `common`, `misc` collect unrelated code with no owner and become cycle magnets. Name the real home (`money`, `dates`, `slugify`).
- **One job per module**, nameable in a sentence without "and" — the function-level SRP from coding-principles, one level up.
- **Split on the change signal, not size:**
  - *Divergent change* — the module edits for several unrelated reasons → split along those reasons.
  - *Shotgun surgery* — one logical change touches many modules → pull that responsibility into one place.
- Co-locate what changes together; separate what changes for different reasons.

## Interfaces & contracts

- **Narrow, stable contract; hide the rest.** Consumers depend on the contract, not internals — so you can rewrite internals without breaking them.
- **Minimal public surface.** Export the few things callers need; keep the rest private. A small surface is a small promise.
- **Don't leak internals.** A domain API returns domain types, not DB rows, ORM entities, or raw vendor responses. Leaking them couples every caller to your storage and vendor choices.
- **Wrap external systems behind a port** (ports & adapters / hexagonal). DB, HTTP clients, queues, and vendor SDKs sit behind an interface your core owns; the concrete adapter lives at the edge. The core stays testable and swappable.

## Cross-cutting & data flow

- **One owner per piece of state.** Two writers to the same state is a race and a debugging trap. Route writes through the single owner.
- **Data flows one way.** Prefer a clear direction (input → transform → output) over parts calling back into each other. Bidirectional and circular flow is where surprising bugs live.
- **Push side effects to the edges.** Keep the core deciding on plain inputs; do I/O (read, write, send) at the boundary. A pure core is easy to test and reason about.
- **Inject config and secrets at the edge.** Pass them in from the entry point; don't read env/config deep inside domain code — deep reads hide dependencies and break tests.
- **One error strategy per layer.** Decide where errors are handled vs. propagated, and be consistent. Don't swallow an error at a boundary to make a caller look clean.

## Don't over-architect

YAGNI for structure. A wrong boundary is paid on every crossing and is expensive to unwind.

- No new layer, service, package, interface, or extension point until a *second real* case needs it. One implementation behind an interface is just indirection.
- Don't split into services/modules before there's a real seam — a separate change rate, team, or scaling need. "Might need to scale" is not a seam.
- A monolith you can refactor beats a distributed system you can't. Distribution adds network, partial failure, and versioning costs — take them on for a real reason.
- Add the boundary when the second caller, the real scaling limit, or the real team split arrives. Flag the future need instead of building for it.

## Rationalizations

| Excuse | Reality |
|---|---|
| "We'll need this layer later" | The boundary costs you on every call now. Add it when the second case is real. |
| "A `shared` module avoids duplication" | It becomes a cycle magnet and a junk drawer with no owner. Name the real home. |
| "Just import the SDK here, it's quick" | Now the core can't be tested or swapped. Wrap it at the edge. |
| "Microservices will scale better" | They add network and partial-failure costs today for scaling you may never need. |
| "The cycle works, leave it" | Until you try to test, build, or change either side alone. Break it now. |
| "Returning the DB row saves a mapping" | Every caller is now coupled to your schema. Map at the boundary. |

## Red flags

- A new dependency that closes a cycle (A → B → A, even through a chain)
- Core/domain code importing a vendor SDK, ORM, or framework type
- A new file landing in `utils` / `shared` / `common` / `misc`
- A module you can only describe with "and"
- One logical change that edits five modules
- A public export that exposes an internal, DB, or vendor type
- Two places writing the same state
- Config or `env` read deep inside domain logic
- A new layer, service, or package whose only caller is hypothetical
