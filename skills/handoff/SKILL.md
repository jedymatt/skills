---
name: handoff
description: Use when wrapping up a work session and you want to save what is done and what is left for a future session to pick up — triggers on "save handoff", "hand off", "wrap up the session", "save my progress for next time". For reading a saved handoff back, use load-handoff.
---

# Handoff (save)

## Overview

Save a short, forward-looking note so the next session can continue cleanly. The note is grouped into **topics** — one per thing you are working on, named after the git branch by default. You choose which topics carry into the next handoff.

## Where it lives

- File: `<repo-root>/.handoff/handoff.md`
- Repo root: `git rev-parse --show-toplevel` (if it is not a git repo, use the current directory).
- Keep it out of git: make sure `<repo-root>/.handoff/.gitignore` holds a single line `*`. Create the folder and this file if they are missing. The `*` makes git ignore the whole folder (including itself), so it never shows in `git status`. Do NOT touch the repo's root `.gitignore`.

## File format

```
# Handoff

## <topic> — <YYYY-MM-DD>
### State
{what is done / not done. files, branches, PR numbers, decisions. 2–4 lines}
### Next
{what to pick up, in priority order. 1–3 items}
### Context
{non-obvious gotchas, blockers, preferences — skip if none}
```

Write in first person ("I…"), forward-looking, about 20 lines or fewer per topic.

## Steps

1. Find the repo root and read `<root>/.handoff/handoff.md` if it exists. Note the existing topic headings (`## …`).
2. Decide the current topic name: the git branch (`git rev-parse --abbrev-ref HEAD`), unless the user gave a label.
3. **Pick which topics to keep** for the next handoff:
   - If the user named topics to keep or drop (e.g. "drop the old one", `keep=…`, `remove=…`), apply it.
   - If the user said nothing, **keep all** existing topics — do not drop anything by accident.
4. Refresh the current topic: write its State / Next / Context from this session, and stamp the heading with today's date (`date +%F`). If the topic already exists, replace its block; otherwise add it at the top.
5. Write the file back with the kept topics plus the current topic. Make sure the `.gitignore` from "Where it lives" exists.
6. Confirm in one line: which topic you saved, and the full topic list now in the file.

## Notes

- No automatic cap and no date-trimming — you curate the topic list.
- This skill only writes. To read a handoff back, use **load-handoff**.
