---
name: Four axioms of software design
description: The root axioms from which all design principles derive — used to audit decisions systematically instead of memorizing principle lists
type: project
---

Albert wanted a systematic, exhaustive way to know all relevant principles. We discovered that principles derive from 4 axioms:

1. **Honest representation** — code means what it says
2. **Composition** — parts combine predictably
3. **Minimal knowledge** — each part knows only what it needs
4. **Essential over accidental** — fight the right complexity

**Why:** Memorizing principles is fragile — you can't know what you don't know. Understanding axioms lets you derive principles for novel situations.

**How to apply:** When auditing any decision, ask: (1) Does the code say what it does? (2) Do parts compose predictably? (3) Does each part know only what it needs? (4) Is this complexity from the problem or from my solution? If a decision violates an axiom, there's a problem. If two axioms conflict, there's a real tradeoff to resolve.
