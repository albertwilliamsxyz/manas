# Manas — Architecture Essay & Development Plan

> Instructions: Read this as an essay. Add your comments below any section using
> `<!-- your comment -->` or plain text. This document is a dialogue.
> Nothing here is final. Everything is a question as much as a statement.

---

## I. What Manas Actually Is

Before talking about code, we need to be honest about what this program is
trying to be. The README says "elevate human cognition." But that's a direction,
not a destination. A more precise statement:

Manas is a spatial, embodied interface for externalizing and manipulating
conceptual structures. It uses the AR environment as an extension of working
memory — not as a game world, not as a 3D file manager, but as a cognitive
workspace where the arrangement of objects in space carries meaning. The hand
is not a cursor. It is the primary instrument of thought.

This distinction matters architecturally. Most 3D graphics codebases model a
scene: objects with positions, cameras, lights. Manas needs to model a universe
of meaning: concepts with relationships, operations with semantics, spatial
metaphors with interpretive weight.

The code does not reflect this yet. The code models a GL context with a cube
and two hands. The distance between those two descriptions is the entire
development roadmap.

<!-- YOUR THOUGHTS: -->


---

## II. The Current State: An Honest Inventory

`main.ts` is 596 lines. It is a single file containing:
- Constants (joint indices, vertex data, shader source)
- GL initialization (context, shaders, program, uniforms)
- WebXR initialization (system check, session, reference space)
- Buffer and VAO setup (cube, left hand, right hand, skeleton)
- The runtime loop (input reading, gesture computation, rendering)
- Type definitions (Model, Geometry, Scene) that are never used
- Utility functions (createXRSystem, isWebXRSessionModeSupported) that are also
  never used

Every one of these is a legitimate system. None of them are wrong to exist.
The problem is that they all live in the same room with no walls between them.
You cannot reason about one without accidentally seeing all the others.

The GL initialization pipeline — from `createGraphicLibraryContext` to
`initializeProgram` — is well-designed. It uses `fp-ts Either` to track errors
explicitly. Each step is a named function with a clear input and output.
This part of the code is good. Preserve its spirit.

The runtime loop is where discipline dissolves. `onXRFrame` reads input, computes
gesture state, uploads buffers to the GPU, clears the framebuffer, sets uniforms,
and draws geometry — all in sequence, all in one function, all entangled. It also
`console.log`s the pinch distance every frame, allocates multiple `Float32Array`
objects on every tick (pressuring the garbage collector at 60fps), and contains
an empty `if` block for the right hand that does nothing.

The types `Model`, `Geometry`, and `Scene` are defined after the GL setup,
inside the async IIFE body, and never referenced. They are the ghost of the
architecture that should exist.

<!-- YOUR THOUGHTS: -->


---

## III. The Three Laws the Code is Not Obeying

There are three principles whose violation accounts for most of the problems.

**Law 1: Separate declaration from execution.**

Some code should run once (at startup). Some code should run every frame.
Currently these are indistinguishable from each other. Buffer creation,
VAO binding, and `gl.bufferData` calls appear sequentially in the IIFE body
alongside type definitions and function declarations. The reader must trace
every line to know what is setup and what is runtime.

The fix is structural: startup code belongs in functions named for what they
initialize (`initializeGraphics`, `initializeHandBuffers`). The IIFE body
should only call these functions in order, then start the loop.

**Law 2: Separate pure computation from effects.**

Reading from `frame.getJointPose()` is an effect — it touches hardware.
Uploading to `gl.bufferSubData()` is an effect — it writes to the GPU.
Computing the Euclidean distance between two joint positions is not an effect
— it's pure arithmetic. These three things currently live in the same function
body with no distinction.

Pure computations (gesture detection, joint math, state transitions) should
be extractable functions that can be called with data and return data. They
should know nothing about WebGL. Effects (reading XR, writing GPU) should
be as thin as possible — just translations at the boundary.

**Law 3: The state of the world should be a value, not a scattered assumption.**

Right now the "state" is spread across: the GPU buffers (where hands currently
are), the uniform variables (what color things are), and the implicit
assumptions of the render loop (which VAOs are bound when). There is no single
place that answers the question "what is the world right now?"

A `Universe` value — a plain TypeScript object — should hold everything that
is true at this moment: where hands are, what objects exist, what the current
gesture state is. The render loop reads from this value. The update function
produces new versions of it. Nothing else needs to know how the GPU works.

<!-- YOUR THOUGHTS: -->


---

## IV. The Five Systems That Need to Exist

Looking at the code as it is, here are the five distinct systems that are
currently tangled together. Understanding them as separate things is the first
step. Separating them in code comes later, at your own pace.

**System 1: Graphics Initialization**

Goal: take a canvas element, return everything the renderer needs to draw.
Inputs: `HTMLCanvasElement`.
Outputs: compiled shader program, uniform locations, pre-allocated GPU buffers,
VAO handles.
Nature: runs once. Mostly effectful (talks to GPU). Already well-handled by
your `Either`-based functions.
Problems: `createProgram` doesn't check for null. `gl.createVertexArray()` and
`gl.createBuffer()` return nullable types that are coerced without checking.

**System 2: XR Session Management**

Goal: manage the lifecycle of the WebXR session.
Inputs: `XRSystem`, a compatible `WebGL2RenderingContext`.
Outputs: `XRSession`, `XRReferenceSpace`, `XRWebGLLayer`.
Nature: async, effectful, stateful (the session is a live connection to hardware).
Problems: `createXRSystem` and `isWebXRSessionModeSupported` were written with
the right instinct (wrap in Either/TaskEither) but then bypassed. The session
lifecycle has no cleanup.

**System 3: Input Reading**

Goal: given an XR frame and input sources, extract what is happening with the
user's hands and produce typed data.
Inputs: `XRFrame`, `XRInputSourceArray`, `XRReferenceSpace`.
Outputs: joint positions per hand (pure data).
Nature: effectful at the read boundary, but the output should be pure data
that knows nothing about XR types.
Problems: input reading, gesture computation, and buffer uploading are
currently fused. Reading position is an effect. Computing pinch distance
from positions is pure. These should be separate acts.

**System 4: State / Universe**

Goal: hold the complete description of the world at the current moment.
This is the system that currently does not exist in working form.
What it contains: hand state (joint positions, gesture flags), scene objects
(their positions, identities, relationships), application mode.
Nature: purely a data structure. A TypeScript object. No methods, no GL.
Problems: `Model`, `Geometry`, `Scene` are defined but not used. `cubePosition`,
`cubeRotation`, `cubeScale` are declared but never fed into any transform.
The universe exists in the comments and type stubs but not in execution.

**System 5: Rendering**

Goal: given the current state of the world and an XR view, produce draw calls.
Inputs: current Universe, `WebGL2RenderingContext`, `XRView`.
Outputs: none (pure side-effects to the GPU).
Nature: fully effectful, but should be stateless — same Universe + same view
= same pixels. It should not make decisions. It executes instructions.
Problems: currently mixed with input reading. Buffer uploads (input concern)
happen before draw calls (render concern) in the same function body.
More critically: no matrix math means objects cannot be positioned. The model
matrix is always identity. The cube never moves regardless of `cubePosition`.

<!-- YOUR THOUGHTS: -->


---

## V. The One Missing Piece That Blocks Everything Else

Matrix math.

Your `LINEAR_ALGEBRA.md` is a comprehensive document. You know what a
translation matrix is. You know how to compose Scale × Rotation × Translation.
The document even shows the exact matrices. But there is no TypeScript function
anywhere in the project that multiplies two `Mat4` values together.

Without this, `cubePosition` is decorative. Without this, objects in Manas
cannot move. Without this, there is no difference between the scene graph in
`DESIGN.md` and the empty types in the IIFE.

The functions you need, in order of priority:

1. `multiplyMat4(a: Mat4, b: Mat4): Mat4` — matrix multiplication
2. `translationMatrix(v: Vec3): Mat4` — builds a translation matrix from a
   position vector
3. `scaleMatrix(v: Vec3): Mat4` — builds a scale matrix
4. `rotationMatrix(v: Vec3): Mat4` — builds a rotation matrix from Euler angles
5. `modelMatrix(position: Vec3, rotation: Vec3, scale: Vec3): Mat4` — composes
   the above into a single transform

These are pure functions. They take numbers, return numbers. They can be written
without a browser, without WebGL, without XR. They can be verified against the
formulas in `LINEAR_ALGEBRA.md` manually. This is the most important thing to
implement next, and it has the lowest risk because it is entirely pure.

There is also the option of importing `gl-matrix` (a well-tested npm package
for exactly this) instead of writing your own. The tradeoff: importing it means
you skip the learning. Writing it means you understand what you're doing.
Given your stated goal of understanding the universe through this program,
writing it — even imperfectly — serves that goal better.

<!-- YOUR THOUGHTS: -->


---

## VI. The Order of Things — A Proposed Sequence

This is not a deadline or a schedule. It is a proposed sequence of understanding,
where each step makes the next one clearer. Each item can be done in an hour
or a week. The order is what matters, not the pace.

**Step 1: Write the matrix math.**
Pure functions. No GL. Verify against `LINEAR_ALGEBRA.md` by hand.
When done: you can compute any transform for any object.

**Step 2: Apply the matrix math to the cube.**
Take `cubePosition`, `cubeRotation`, `cubeScale` and compose them into a real
model matrix. Pass it to `gl.uniformMatrix4fv`. Watch the cube actually go to
`z = -0.5` instead of floating at origin.
When done: you have proof the math is correct. Something moved.

**Step 3: Extract the Universe type to module scope and instantiate it.**
Move `Model`, `Geometry`, `Scene` out of the IIFE. Add the cube as an actual
`Model` value in an actual `Scene`. Add hand state to the scene.
When done: there is a single object that describes the world. Render reads from it.

**Step 4: Separate what happens once from what happens every frame.**
Move buffer/VAO initialization into named functions outside the IIFE.
Make `onXRFrame` only do three things: read input, update state, render.
When done: the loop is readable in 20 lines.

**Step 5: Separate input from rendering inside the loop.**
Extract joint reading into a function that returns data.
Extract gesture computation as a pure function that takes joint data.
Extract the draw calls into a function that takes the Universe.
When done: each of the five systems exists as a named thing you can reason about.

**Step 6: Implement the first real interaction.**
Pick one thing: grab the cube with a pinch. Move it with your hand.
This requires: pinch detection (partially done), hit-testing or proximity
detection, updating the cube's position in the Universe, rendering the new
position via the model matrix.
When done: Manas is no longer a viewer. It is an interface.

<!-- YOUR THOUGHTS: -->


---

## VII. What Not to Do Yet

Some things are worth naming explicitly as out-of-scope for now:

**Do not separate into multiple files yet.**
File structure is the last form of organization, not the first. Understand
the systems conceptually. Make them work in the same file with clear internal
structure. Move to files when the boundaries are so obvious they feel natural.

**Do not reach for ECS yet.**
Entity Component Systems are powerful for games with hundreds of entity types.
You have a cube and two hands. The overhead of an ECS — entity IDs, component
registries, system scheduling — is not justified. Build the Universe as a
plain typed object. You will know when ECS is needed because you will feel
the current approach resisting your needs.

**Do not abstract prematurely.**
The fp-ts wrappers for shader compilation are good. Do not try to make
everything equally wrapped. The loop is allowed to be imperative for now.
Premature abstraction creates complexity without clarity. Add abstraction
when repetition forces your hand, not before.

**Do not add features before the foundation moves.**
The roadmap mentions collision detection, collaborative editing, scene
persistence. These are meaningful. They are also irrelevant until a concept
can be grabbed and moved in space. Walk before flying.

<!-- YOUR THOUGHTS: -->


---

## VIII. The Philosophical Coherence Question

There is a question underneath all of this that the code cannot answer but
the developer must: what is the atom of meaning in Manas?

Your project description says this is about modeling the world. Your
`DESIGN.md` shows a Universe with Models and Entities. The README mentions
exploring ideas and cognition. But what, specifically, is the smallest
meaningful thing that can exist in the AR space?

Is it a concept node — a point in a knowledge graph that represents one idea?
Is it a proposition — a claim that relates two concepts?
Is it a whole theory — a connected subgraph of related claims?
Is it something less linguistic — a felt sense, a metaphor, a spatial intuition
that doesn't reduce to a node in a graph?

This question is not abstract. It determines what `Model` contains. It
determines what a relationship type can be. It determines what a gesture
means — whether pinching is "selecting a concept" or "grasping a proposition"
or something else entirely.

The answer doesn't have to be final. But having a working hypothesis changes
the code. A `Model` that is a concept node has different fields than a
`Model` that is a spatial attention anchor. The gesture vocabulary for a
knowledge graph is different from the gesture vocabulary for a meditation tool.

What is the atom?

<!-- YOUR THOUGHTS: -->


---

*End of plan. Comment anywhere. Nothing here is a contract.*
