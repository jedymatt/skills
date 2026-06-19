---
name: load-handoff
description: Use when starting a session and you want to pick up where you left off — triggers on "where was I", "catch me up", "continue", "what was I doing", "load handoff", "load the handoff". Reading only. To save a handoff, use handoff.
---

# Load Handoff (read)

## Overview

Read back the handoff note saved by the **handoff** skill so you can continue cleanly. Read-only — this skill never writes.

## Where to look

- File: `<repo-root>/.handoff/handoff.md`
- Repo root: `git rev-parse --show-toplevel` (if it is not a git repo, use the current directory).

## Steps

1. Find the repo root and read `<root>/.handoff/handoff.md`.
2. If the file is missing or empty, say so plainly — "No handoff found for this repo." — and stop.
3. Show the handoff:
   - Default: show all topics, newest first.
   - If the user named a topic (e.g. "load ytd-pairing", `topic=…`), show just that topic's block. If it is not there, say so and list the topic names that are.
4. Use it as your starting context for the session — the **Next** lines are what to pick up first.

## Notes

- This skill never edits the file. To update or save a handoff, use **handoff**.
