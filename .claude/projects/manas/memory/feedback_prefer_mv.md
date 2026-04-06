---
name: Prefer simple commands
description: Use mv/rename instead of mkdir+copy when reorganizing files/directories
type: feedback
---

Use the simplest command for the job — `mv` to rename/move, not `mkdir` + copy + cleanup.

**Why:** I pointed out `mv` was the right tool when Claude used `mkdir` to reorganize a directory. Unnecessary steps waste time and show lack of thought.

**How to apply:** Before running a shell command, ask: is there a simpler way? Prefer single atomic operations over multi-step equivalents.
