---
name: storyboarding-prs
description: Storyboard a PR as an interactive local HTML page, Before and After on the same steps, each showing who acts, in which app, and what it does to the data, then open it in the browser. Use when the user asks for a storyboard, an HTML visual, or a picture of what a PR fixes or how a bug happens ("draw it", "show me"), even without the word storyboard. For a written walk-through, use explaining-prs.
---

# Storyboarding PRs

A one-page, step-through picture of a change: Before and After side by side on the same steps, each step showing **who acts**, **the app they're using**, and **what it does to the data**. The reader uses it to understand a bug or fix at a glance and judge it, so the picture has to be accurate and the turning point has to stand out.

`assets/template.html` is the finished engine, filled with a worked example (a shop's Create order retry). Copy it and replace only the block between `THE STORY` and `end of THE STORY`. The engine already handles the layout, dark mode, keyboard, narrow screens and the link line; keep it as it is.

## 1. Understand the change from the code

Read the PR the way explaining-prs does: the diff and the code around it, with the body only as a map. Then check every detail the storyboard will show against the code, because the reader takes the picture literally:

- **Messages:** quote toasts, errors, tooltips and labels exactly as the code has them. Note whether each is an app-level toast or a message inside a drawer or panel, and draw it in that place.
- **Navigation:** what closes and what opens after the action (a drawer closing, the page moving to a new record). Draw the screen the person actually ends up on.
- **Who does what:** which steps a person does and which the system does behind a click.

Anything you can't confirm, paraphrase, and say so in the `fine` print.

## 2. Find the shortest story

Aim for 3 to 5 steps, one per **human action** (an upload, a click). What the system does behind that click goes **inside** the step as a checklist (`checklist(...)`). Eight steps read as too many; four read well.

- Steps that are the same in Before and After come first, as plain steps.
- The step where the versions part ways is a split step: `{ before: {...}, after: {...} }`, with `tone: 'bad'` and `tone: 'good'`. Usually it's the last one or two. That's where the colour goes.
- A split step that differs only in a detail (something remembered, how the work is divided) gets `same: true`, so it isn't flagged as the turning point.
- Say outright when a step is ordinary rather than the bug ("An ordinary failure, e.g. a dropped connection"), so the reader doesn't hunt for a problem in it.
- **A refactor with no visible change:** draw the flow that uses the moved code as same-in-both steps, show the internal split as a `same: true` step, and end on what the refactor enables (the follow-up PR) as the one toned split step, labelled as that PR's.

## 3. Cast and apps

- **Actors:** the people and the system, each with an icon (`person`, `pro`, `system`) and a colour. Use made-up names and say so in `fine`.
- **App per step:** pick the scene builder that matches what they're looking at: `phone(...)` for a customer's phone app, `browser(...)` for a web page with an optional side panel and app toast, `checklist(...)` for the system's work. The hot button gets `hot: true`.
- Name things in the product's own terms ("Order A", not "record" or "entity"). Code names stay out of the visible text.

## 4. What it does to the data

The bottom half of each step shows the consequence: the places the thing can be linked to (`world.cards`) and the thing itself (`world.item`), with a moving line to where it's linked now. Per step, state `link`, any `absent` cards, and card `state: 'lost' | 'kept'` with a short `msg` at the turning point. When the change isn't about where something ends up, omit `world` and the section disappears.

## 5. Keep it quiet

Readers asked for less noise and more room, not a compact page:

- Colour only where Before and After differ: the red border and red tasks for Before, green for After. Everything the two share stays neutral, including messages (the `tip` style in the template draws a neutral tooltip).
- Below the step-through, at most two short sections: why the bad outcome matters, and any merge-order note (`chips`). Add a glossary, code-change list or keyboard hints only when asked.
- One big line (`what`) and one short line (`why`) per step.

## 6. Verify, then open

1. Write the file to a scratch directory, e.g. `<scratch>/pr<N>-storyboard.html`.
2. Syntax-check the script: extract the `<script>` body to a temp `.js` and run `node --check`.
3. Look at it in a browser. Browser tools often can't open `file://`, so serve a copy with `python3 -m http.server 8765 --bind 127.0.0.1` in the background and open `http://127.0.0.1:8765/`. Screenshot the first step and both versions of each split step. Check the narrow layout by loading the page into a 420px-wide iframe and calling `go(n)` on its window: no sideways scroll, and the link line must not cross another card. Close the tab and stop the server afterwards.
4. `open <file>` (or the platform's equivalent) so it appears in the user's browser.

Reply with the full file path and a line per step on what it shows. Say which steps you checked in the browser and what you fixed.

## Updating one

When the user asks for changes, edit the same file and reopen it. If a review flags something (a picture that doesn't match the code, a layout bug), verify it against the code or the page first, then fix it.
