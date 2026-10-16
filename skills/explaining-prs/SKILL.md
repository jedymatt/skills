---
name: explaining-prs
description: Explain what a pull request does in plain terms, with the behaviour before and after, walked through step by step. Use whenever the user shares a PR link or number and asks "what does this do?", "what's the before and after?", "walk me through this PR", "explain this change", or wants to understand a PR before reviewing, approving, testing or describing it to someone else, even if they don't say "step by step". Also use for a branch or commit range when the question is what changed in behaviour. Not for reviewing a PR for bugs or risk (use code-review or reviewing-for-risk) or writing a PR description.
---

# Explaining PRs

The reader wants to understand what changes for the person using the software. They don't want a tour of the diff. The format that works is a numbered walk-through of what happens, once as it was and once as it is now, so they can see exactly which step changed and what that step now leads to.

## 1. Read the PR, then the code

```bash
gh pr view <n> --json url,title,body,baseRefName,headRefName,files \
  --jq '.url, .title, .baseRefName, .headRefName, (.files[]|"\(.additions)+ \(.deletions)- \(.path)"), "-----", .body'
gh pr diff <n>
```

Use the PR body only to find your way around. Base every claim on the diff and the code around it, because bodies go stale when a PR is reworked. If the body and the code disagree, go with the code and say so. For a large diff, read the files that change behaviour first. Skip tests, renames and lockfiles until the story is clear.

Quote every message the user sees (toasts, errors, labels) exactly as it appears in the code. A paraphrased error message won't match what the reader later sees on screen.

## 2. Find the flow and the separate changes

- **The flow:** the sequence of things the user or system does in the area this PR touches. You'll number these steps, so name them first.
- **The changes:** a PR often fixes two or three separate things. Each one gets its own before and after. Don't blend them into one story.
- **The trigger:** the exact conditions under which the old behaviour went wrong, for example "only when the payment fails after the order is saved", or "only when the customer changed a setting first". A bug that needs a specific path is easy to misread as always happening.

## 3. Write it up

Use this shape and leave out the parts that don't apply:

```markdown
[#NNNN](https://github.com/<owner>/<repo>/pull/NNNN) fixes/adds <one sentence in plain terms: what, for whom, when>. <Blocker or not, if the PR says.>

<The flow, only if the reader needs it to follow the steps:>
Clicking **X** runs three steps:
1. **Step name:** what it does.
2. …

## Fix 1: <what went wrong, in the user's terms>

**Before:**
1. **Customer:** <what they do that sets this up>
2. **Admin:** <what they open or click>
3. **<Named screen or step>:** <the step where it goes wrong>
4. **Admin:** <the visible result, e.g. the exact error text, or nothing at all>

**After:**
1. to 2. are the same.
3. **<Named screen or step>:** <what happens now instead>
4. **Admin:** <the new result>

## Fix 2: …

## Code changes
- **`path/file.ts`:** what changed, in one line.
```

What makes this work:

- **Lead every step with who acts, in bold.** Name the people involved (for example **Customer:**, **Admin:**) and the exact screen, step or drawer the software shows (for example **Refund step:**), never a vague "Page:" or "System:". The reader should be able to see the interactions between people and screens, so start the walk-through with the action that sets things up, even when another person does it, such as the customer placing the order.
- **One action or event per step.** Number the steps so that Before and After line up. Where After's first steps match Before's, write "1. to 2. are the same." That points the reader straight at the step that changed.
- **End Before on the consequence,** not the mechanism: what the user sees, or what silently goes wrong. "Nobody else changed the order; the admin's own save caused the mismatch" is the line that makes the bug land.
- **Use concrete values.** "Price $90 → $95", "last edited T1, then T2" and "a file uploaded between attempts" are easier to follow than abstract descriptions of state.
- **Say where it applies,** such as which screens or entry points. Also say what already worked, so the reader doesn't think the PR fixed more than it did. For example: "(A retry with the same settings already worked.)"
- **Keep code names out of the walk-throughs.** Put function and file names in the "Code changes" list at the end, and keep the steps in the product's own terms.
- **Link every PR number, every time it appears,** as `[#NNNN](https://github.com/<owner>/<repo>/pull/NNNN)`, not only its first mention. The reader jumps between sections, so a link in the opening line doesn't help them further down. That covers headings, walk-throughs, findings and verdicts, and also PRs you only mention, such as the rest of a stack or an older PR that caused the bug. The reader wants to open them without searching. Take the URL from `gh pr view --json url`, and don't guess the repo.
- **Keep the "Code changes" list short:** one line per file that matters. Group the test changes into one bullet.

## Adapting

- **A new feature, not a fix:** "Before" is how the user did it without the feature, or that they couldn't. "After" walks through the new flow.
- **Refactor with no behaviour change:** say that plainly and skip the step-by-step. Explain what moved and why in a few bullets.
- **A change the user can't see** (server-side, data, performance): the steps can be what the system does, still led by the named part that acts, such as "**Orders API:** reads…", "**Order page:** applies…". Still end each walk-through on the result someone would notice.
- **A follow-up question about one fix:** answer only that fix in the same shape. Don't repeat the whole explanation.
