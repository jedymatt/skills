---
name: writing-plain-english
description: Use when drafting or rewriting any English prose for the user — Slack messages, daily updates, PR descriptions, commit messages, docs, comments, or replies. Use when the user asks to simplify, reword, or make text sound more natural.
---

# Writing Plain English

## Overview

The user is not a native English speaker. Fancy words sound unnatural coming from them and don't match how they actually talk. **Write the way a person speaks, not the way an essay is written.**

Core principle: **simple word over clever word, short sentence over long sentence.** If a 10-year-old wouldn't use the word, don't use it.

## When to Use

- Any time you write English prose *for* the user (it goes out under their name).
- When the user pastes text and asks to simplify, reword, shorten, or "make it sound natural."
- Applies to: Slack/chat, daily updates, PR descriptions, commit messages, docs, code comments, emails, replies.

Does NOT apply to: code itself, identifiers, or quoting an error message exactly.

## Rules

1. **Pick the plain word.** See the swap table below. When unsure, choose the shorter, more common one.
2. **Short sentences.** One idea per sentence. If a sentence has a semicolon or two em-dashes, split it.
3. **Cut filler.** Drop words that add nothing: *just, really, actually, simply, purely, broadly, meaningfully, quite, very, basically.*
4. **Plain connectors.** Use *so, but, and, also* — not *thus, hence, therefore, moreover, whilst.*
5. **Say it directly.** "I fixed X" not "I went ahead and addressed the X issue."
6. **Keep technical terms and common soft-eng jargon.** The user is a software engineer. Words like *cache, deploy, dedup, monorepo, config, refactor, edge case, race condition, rollback, regression, ship* are fine — they're normal for the audience, not fancy vocabulary. The rule targets fancy *everyday* words, not domain terms.

## Word Swaps

| Fancy | Plain |
|-------|-------|
| leverage / utilize | use |
| facilitate / enable | let / help / make it possible |
| meaningfully / significantly | a lot / by a lot |
| purely / simply | just |
| distinct | separate |
| lurking / latent | hidden |
| commence / initiate | start |
| terminate | stop / end |
| numerous | many |
| approximately | about |
| in order to | to |
| due to the fact that | because |
| prior to | before |
| subsequently | then / after |
| demonstrate | show |
| ensure | make sure |
| additional | more / extra |
| however / nevertheless | but |
| therefore / thus / hence | so |

This table is a starting point, not a limit. Apply the spirit: when a simpler everyday word exists, use it.

## Example

**Fancy (avoid):**
> By leveraging task-level caching and dependency-aware scheduling, unaffected packages are skipped, which should meaningfully cut down pipeline run times.

**Plain (use):**
> This makes CI only rebuild the packages that changed. The rest are skipped or pulled from cache, so CI runs a lot faster.

**Fancy (avoid):**
> I also started reviewing the dedup logic more broadly to make sure there aren't other edge cases lurking.

**Plain (use):**
> I also started looking at the dedup logic to check for other cases I might have missed.

## Defining Hard Words

If you must use advanced or rare words or phrases, add a short block right after the paragraph that defines them in simple English. List one term per line, so several terms can share one block. It is **not limited to a single word** — short phrases or idioms work too. Wrap the headline line and the divider line in backticks so they render in the muted code color (not white), which keeps them quiet. The headline is fixed — use `📘 Word help`, not the term itself. Use the box-drawing character `─` (not plain hyphens, which markdown turns into an invisible rule). Keep the dividers short and let the top and bottom lines differ in length, so the block does not pull attention from the real message. Like this:

`📘 Word help ─────────`
**leverage** — to use something to get an advantage.
**race condition** — a bug where the result depends on timing.
`─────────────────────`

## Self-Check Before Sending

Scan the draft and ask:
- Any word from the Fancy column? Swap it.
- Any sentence longer than ~20 words, or with a semicolon? Split it.
- Any filler word (*just, really, simply, purely*)? Cut it.
- Read it out loud — does it sound like normal speech? If not, simplify again.

## Common Mistakes

- **Dumbing down the meaning.** Simple words, same message. Don't drop technical accuracy — keep *cache*, *deploy*, *config*.
- **Sounding robotic.** Short ≠ choppy. Contractions are good ("it's", "I've", "don't").
- **Stopping after one pass.** The first draft often still has fancy words. Re-scan with the swap table.
