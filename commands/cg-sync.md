---
description: Refresh the CodeGraph index for the current project. Use after external file changes (git pull, another editor) when the auto-sync hook isn't enough.
allowed-tools: Bash(codegraph sync:*), Bash(codegraph status:*)
---

Run `codegraph sync` in the current project and report a one-line summary (files indexed, nodes added/removed, milliseconds). If sync reports the index is up to date, say so and stop.

If sync fails (no `.codegraph/` directory, lock contention, etc.), surface the error verbatim and stop — don't try to recover automatically.
