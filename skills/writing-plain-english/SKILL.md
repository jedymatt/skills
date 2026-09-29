---
name: writing-plain-english
description: Use when drafting or rewriting any English prose for the user — Slack messages, daily updates, PR descriptions, commit messages, docs, comments, or replies. Use when the user asks to simplify, reword, or make text sound more natural.
---

# Writing Plain English

## Overview

The user is not a native English speaker. Fancy words sound unnatural under their name and don't match how they talk. **Write the way a person speaks, not the way an essay is written.** Core rule: **simple word over clever word, short sentence over long sentence.** If a 10-year-old wouldn't use the word, don't.

## When to Use

- Any English prose written *for* the user (it goes out under their name): Slack/chat, daily updates, PR descriptions, commit messages, docs, code comments, emails, replies.
- When the user pastes text and asks to simplify, reword, shorten, or "make it sound natural."

Does NOT apply to: code, identifiers, or an error message quoted exactly.

## Rules

1. **Pick the plain word.** See the swap table. When unsure, choose the shorter, more common one.
2. **Short sentences.** One idea each. A semicolon or two em-dashes means split it.
3. **Cut filler:** *just, really, actually, simply, purely, broadly, meaningfully, quite, very, basically.*
4. **Plain connectors:** *so, but, and, also* — not *thus, hence, therefore, moreover, whilst.*
5. **Say it directly.** "I fixed X", not "I went ahead and addressed the X issue."
6. **Keep technical terms and common soft-eng jargon.** The user is a software engineer — *cache, deploy, dedup, monorepo, config, refactor, edge case, race condition, rollback, regression, ship* are normal, not fancy. The rule targets fancy *everyday* words, not domain terms.

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

A starting point, not a limit: when a simpler everyday word exists, use it.

## Examples

**Fancy:** By leveraging task-level caching and dependency-aware scheduling, unaffected packages are skipped, which should meaningfully cut down pipeline run times.
**Plain:** This makes CI only rebuild the packages that changed. The rest are skipped or pulled from cache, so CI runs a lot faster.

**Fancy:** I also started reviewing the dedup logic more broadly to make sure there aren't other edge cases lurking.
**Plain:** I also started looking at the dedup logic to check for other cases I might have missed.

## Self-Check Before Sending

- Any word from the Fancy column? Swap it.
- Any sentence over ~20 words, or with a semicolon? Split it.
- Any filler word (rule 3)? Cut it.
- Read it aloud — does it sound like normal speech?

## Common Mistakes

- **Dumbing down the meaning.** Simple words, same message — keep the technical accuracy.
- **Sounding robotic.** Short ≠ choppy. Contractions are good ("it's", "I've", "don't").
- **One pass isn't enough.** The first draft still has fancy words. Re-scan with the swap table.
