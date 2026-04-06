---
name: Progressive crystallization process
description: How abstractions emerge in Manas — comments first, then names, then types, then functions, then modules. Never skip steps.
type: feedback
---

Albert's process for discovering architecture is layered and empirical:

1. All new functionality lives in Main first (the crisol)
2. Comment potential patterns to mark them
3. Update naming to reflect emerging abstractions
4. Define types when the concept is clear
5. Extract functions when a pattern repeats 3-4 times
6. Extract modules when a group of functions has clear identity

**Why:** Albert discovers which parts are more stable vs mutable over time. Premature extraction creates wrong abstractions. The monolith is where patterns become visible before being abstracted.

**How to apply:** Never jump to "let's create a module." Start with comments and naming. Propose extraction only when there's evidence of repetition or clear conceptual identity. When working in Main, respect that it's a workspace, not a mess.
