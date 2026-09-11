---
name: handoff
description: Write or update a handoff document so a fresh session can continue this work, and arm it so the next session picks it up automatically. Use when the context guard reports the budget is reached, before clearing a conversation mid-task, or whenever the user asks for a handoff.
---

# Handoff

Capture the state of the current work in `.claude/HANDOFF.md` so a session with
no memory of this conversation can continue it without re-deriving anything.

The reader is a fresh instance of you: it has the repository and nothing else.
Everything you know that is not in the code has to be in this document or it is
lost.

## Steps

1. Find the project root — the git root of the working directory, or the
   working directory itself. The document goes at `<root>/.claude/HANDOFF.md`.
2. If that file already exists, read it first. You are updating it, not
   replacing it: keep what is still true, correct what is not.
3. Write the document with these sections:
   - **Goal** — what we are trying to accomplish, in the user's terms.
   - **Current Progress** — what is done, with paths, and the state each file
     is in (committed, staged, dirty, untracked). Include the branch.
   - **What Worked** — approaches that succeeded and are worth continuing.
   - **What Didn't Work** — approaches that failed and why, so the next session
     does not spend its context retrying them.
   - **Next Steps** — concrete, ordered actions. The first one must be
     directly actionable without asking the user anything.
   - **Open Questions** — anything you were going to ask the user but hadn't,
     and any decision the user made that the code does not record.
4. Be specific over brief. Absolute paths, real command lines, actual error
   text, exact function and file names. The next session cannot ask you what
   you meant, and a vague handoff costs more context than it saves.
5. Arm it, so the next session started here picks it up without the user
   pasting anything:
   ```sh
   ~/.claude/hooks/ctx-arm-handoff.sh <root>/.claude/HANDOFF.md
   ```
6. Tell the user the path, and that pressing `/clear` now starts a fresh
   session that continues from the handoff.

## Notes

- The pointer is one-shot and directory-scoped: only the next session started
  in this directory consumes it. The document stays on disk afterwards.
- `.claude/HANDOFF.md` is a working note, not a deliverable. Don't publish it,
  and don't commit it unless the user asks.
- Delete it once the work it describes is finished.
