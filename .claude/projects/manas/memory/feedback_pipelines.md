---
name: Pipelines as thinking tool
description: Albert chose PureScript specifically because pipelines help him think about programs as independent processes. Extract clear pipelines in code.
type: feedback
---

Pipelines are a primary reason Albert chose PureScript. They help think about the program in terms of processes, independent of the intermediate pieces.

**Why:** Each pipeline stage consumes one type and produces another. When not working on an intermediate step, you can reason about the pipeline without knowing the step's internals. This matches how Albert thinks about architecture.

**How to apply:** When refactoring, identify pipeline stages (input → gestures → interaction → render commands → GPU). Extract them using the progressive crystallization process (comments → names → types → functions). tick should become a clear composition of pipeline stages.
