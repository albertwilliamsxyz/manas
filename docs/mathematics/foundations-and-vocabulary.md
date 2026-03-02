# Manas — Foundations: Vocabulary, Concepts, and Design Principles

> A companion to PLAN.md. Add your comments below any section with `<!-- -->`.
> This document answers the conceptual questions before the implementation ones.

---

## I. The Vocabulary of Manas — A Precise Ontology

The first act of architecture is naming. A word used imprecisely in the
foundation will cause confusion at every level built on top of it. The goal
here is not to coin new terms but to assign precise meanings to ordinary words
so that the whole project uses them consistently.

**Universe**
The complete state of everything that exists at a given moment. There is
exactly one Universe at any frame. It is a value — a plain data structure.
It answers the question: "if I had to resume this exact moment, what would
I need to save?" The Universe does not do anything. It is not an actor. It
is a description of reality.

**Scene**
A named, persistent configuration of entities. The Universe can contain
multiple Scenes, but only one is active at a time. A Scene is what you save
to disk, what you share with others, what you return to. It is a document.
The difference from Universe: the Universe is the runtime state; the Scene
is the persisted intent. Example: if you close and reopen the app, the
Universe is rebuilt from the Scene.

**Entity**
The abstract base of everything that has an identity in the world. An Entity
exists and has a unique ID. It may have spatial presence, content, behavior,
or relationships — or none of these. Everything is an Entity. This is
deliberately the most abstract word in the vocabulary.
Entity subtypes:
- **Object** (or Model): an Entity with geometric representation in space
- **Document**: an Entity that displays external content (PDF, image, text)
  as a floating surface in space
- **Drawing**: an Entity composed of user-created strokes
- **Relation**: a directed connection between two Entities with a type

**Transform**
The spatial description of where an Entity is: position, rotation, scale.
A Transform is a value. It corresponds to a 4×4 matrix when sent to the GPU.
It is not the matrix itself — it is the semantic description from which the
matrix is computed.

**Geometry**
The shape of an Object: vertices, indices, how to draw them (points, lines,
triangles). Geometry is data. Multiple Objects can share one Geometry
(two cubes = two Objects, one Geometry). Geometry has no position.

**Input**
Raw data from the physical world before interpretation. Controller state,
joint positions, mouse coordinates, key presses. Input is read by the
Input Adapter layer and converted into Events.

**Event**
A typed, immutable value that describes something that happened. Events are
past tense — they are facts. `PinchStarted`, `ModelMoved`, `DocumentLoaded`.
Events do not have effects. They are data. The update function processes them.

**Effect**
A computation that interacts with the world outside the program: reading
hardware, writing to GPU, accessing the network, generating randomness.
Effects are how Events are produced (input effects → Events) and how the
Universe is made visible (Universe → render effects). Effects are verbs.
Events are nouns.

**Session**
The lifecycle of one XR experience: from the moment the user clicks "Start"
to the moment they exit. The Session holds the hardware connection. It is
NOT part of the Universe. It is the channel through which the Universe is
experienced.

**Command**
(future concept) The outward counterpart of an Event. If Events describe
what happened, Commands describe what to do. `SaveScene`, `LoadDocument`,
`ExportDrawing`. Commands are produced by the update function and executed
by the effect layer. Commands are how the app initiates effects; Events are
how the app receives effects.

<!-- YOUR THOUGHTS: -->


---

## II. Effects vs Events — A Complete Picture

These two words are often confused. They exist in different categories of
thought and serve completely different roles.

### What is an Effect?

An effect is a property of a FUNCTION, not a value. A function has an effect
if it does something observable beyond returning its value. Effects include:

- Reading from hardware: `frame.getJointPose()` reads sensor data
- Writing to GPU: `gl.drawArrays()` changes what the screen shows
- Reading time: `Date.now()` reads the system clock
- Generating randomness: `Math.random()` reads entropy
- Writing to console: `console.log()` writes to stdout
- Network access: `fetch()` sends packets

Effects are always present-tense, always verifiable by asking: "if I called
this function twice with the same arguments, would the result be identical
and would nothing else change?" If no: it has effects.

A function with no effects is called PURE. A pure function is a mathematical
function — same input, same output, always. It can be tested in isolation,
memoized, parallelized, reasoned about without running it.

### What is an Event?

An event is a VALUE — a typed, immutable data structure — that REPRESENTS
something that occurred at a specific point in time. Events are past tense.
They are facts, named and shaped.

```
{ type: 'PINCH_STARTED', hand: 'left', position: [x, y, z] }
```

This event value is pure data. It has no effects. It is a noun, not a verb.
Creating this value is pure. Reading it later is pure. Processing it to
produce new state is pure.

### How They Relate

The architecture of a functional reactive system can be described as:

```
World (hardware, time, sensors)
  ↓  [EFFECTS — reading]
Raw Data (joint positions, frame timestamps, button states)
  ↓  [pure functions — interpretation]
EVENTS (typed facts about what happened)
  ↓  [pure function — update]
New UNIVERSE (new state of the world)
  ↓  [EFFECTS — writing]
World (GPU, screen, audio)
```

The effects are at the boundary. The events are the bridge from messy
reality into the clean type system. Once you have events, everything inside
is pure.

### Related Concepts

**Side Effect**: An effect that is a secondary consequence of a function
whose main purpose is to compute something. `console.log` inside a math
function is a side effect. The goal is to make all effects intentional and
at the boundary, never accidental and embedded.

**IO / Task**: In Haskell and fp-ts, a `Task<A>` or `IO<A>` is not an effect.
It is a DESCRIPTION of a computation that will perform effects when executed.
`TaskEither<Error, boolean>` is a pure value — a promise-returning function —
that, when called (`()`), produces effects. This is how FP "wraps" effects:
the effect is delayed, made explicit, and composable.

**Command (Elm)**: In Elm, the update function returns `(Model, Cmd msg)` —
new state AND a list of commands. Commands describe outward effects to perform
(send HTTP request, play audio). This separates "what the new state is" from
"what effects to trigger." This is the cleanest version of this pattern.

**Signal (FRP)**: A Signal or Behavior in FRP is the continuous version of
an Event — a value that varies over time. `Behavior<Vec3>` is a joint position
at every moment, not just at discrete frame ticks. This is the FRP answer to
the question "what is time?"

<!-- YOUR THOUGHTS: -->


---

## III. A Naming Convention System

The precision of a name matters because names are the primary way you think
about code between sessions. A well-named function needs no comment.

Here is a principled system for the lifecycle of a resource in this program:

**declare** — a type-level statement that something of a certain kind exists.
No runtime cost. Only exists in TypeScript's type system. Erased at compile.
> `type Vec3 = ...`, `interface Entity { ... }`

**define** — assigning a concrete value to a name. Runtime cost: the value exists.
> `const IDENTITY_MATRIX = new Float32Array([1,0,0,...])`

**create** — a runtime action that produces a new resource that did not exist
before. Implies allocation. Often requires a context (gl, system) to operate.
Returns the new resource.
> `gl.createBuffer()`, `gl.createVertexArray()`

**initialize** — takes an existing but uninitiated resource and puts it into
a usable state. Comes AFTER create. May upload data, set parameters, compile.
> `gl.bufferData(...)`, `gl.compileShader(...)`, `gl.linkProgram(...)`

**setup** — informal. Avoid in code. Use it in comments and conversation.
When you want to write `setup`, ask: is it creating? initializing? configuring?

**allocate** — explicitly about memory reservation. Use when you want to
emphasize that memory is being claimed. `allocateHandBuffers`.

**configure** — adjusting parameters of something already created and initialized.
> `gl.enable(gl.DEPTH_TEST)` is configuration, not initialization.

**build** — assembling something from parts. Implies composition.
> `buildModelMatrix(position, rotation, scale)` — builds from components.

**load** — reading external content and producing an in-memory representation.
> `loadDocument(url)` — reads from disk/network, returns an Entity.

**mount** — connecting something to a live, running system. Implies that the
thing and the system both already exist.

**boot** — starting the system for the first time from a cold state.

**start** — beginning a process that continues (like a session, a loop).

**stop / end** — the inverse of start. Not `destroy` unless you are freeing
GPU resources.

**destroy / delete / free** — explicitly releasing resources. Use `delete`
for GPU resources (`gl.deleteBuffer`), `free` for memory, `destroy` for
complex objects with many sub-resources.

### Applied to Manas

```
declare (type level):    type Entity = { id: string, ... }
define (constant):       const EMPTY_UNIVERSE: Universe = { ... }
create (GPU resource):   const buffer = gl.createBuffer()
initialize (GPU state):  gl.bufferData(gl.ARRAY_BUFFER, data, gl.DYNAMIC_DRAW)
build (computation):     buildModelMatrix(position, rotation, scale) → Mat4
load (external):         loadDocument(url): TaskEither<Error, Document>
boot (phase 1):          bootGraphics(canvas): Either<Error, RenderContext>
start (phase 2):         startSession(xr, gl): TaskEither<Error, Session>
```

<!-- YOUR THOUGHTS: -->


---

## IV. Designing the Universe — How to Identify and Define State

The sculptor metaphor you used is exact. The principle is: understand the
shape fully before you cut.

### How to Identify State

Ask three questions about your program:

**1. "What would I need to save to disk to resume this program exactly?"**
Every answer is state. Hand positions: yes. GPU buffer contents: no (they're
derived from hand positions). The shader program: no (rederived from source).
The cube's position: yes. Whether a document is loaded: yes.

**2. "What changes between two different moments in the program's execution?"**
Everything that changes is state. Everything that stays the same is either a
constant or a derived value.

**3. "What does the render function need to know to produce correct output?"**
List these things. That list is your Universe type.

For Manas right now, the honest answer to question 3:
- Where are the user's hands? (joint positions, gesture flags)
- What objects exist in the scene? (Models, their transforms)
- What geometry does each object have? (vertex data)
- What documents are loaded? (Document entities)
- What drawings exist? (Drawing entities)

That's your Universe. Everything else is either derived from it or is ephemeral
(session handles, GPU buffers — things the Universe doesn't need to know about).

### How to Design State

**Principle 1: One truth per fact.**
Each fact about the world appears exactly once. If a joint position appears
in both the Universe AND a GPU buffer, one of them is a derived copy. The
Universe holds the truth; the GPU buffer is a projection of it.

**Principle 2: Normalize, but not at the cost of clarity.**
If something can be computed from other state, don't store it separately.
`isPinching: boolean` could be recomputed from joint positions every frame.
Storing it avoids recomputation and makes the state legible. Use judgment:
store derived state when it names something important.

**Principle 3: The Universe should be as flat as possible.**
Deep nesting makes updates verbose and opaque. Prefer:
```
{ models: Model[], hands: { left: Hand | null, right: Hand | null } }
```
over:
```
{ scene: { spatial: { models: { list: Model[] }, ... } }, ... }
```

**Principle 4: Illegal states should be unrepresentable.**
Use the type system to make invalid states impossible. A `Hand | null` is better
than a `Hand` with an `isTracked: boolean` — you can't have an untracked hand
with valid joint positions if the type is null when absent.

### On Structural Sharing (your PureScript question)

You are right to raise this. When you write `universe = { ...universe, leftHand }`,
JavaScript creates a new object with shallow copies of the unchanged fields.
This is O(1) for the top level but O(n) if you need to update deeply nested
values. And every changed frame creates garbage for the GC.

PureScript (and Haskell) do NOT automatically solve this with persistent data
structures. But they do have:
- **Tail recursion optimization (TCO)**: the loop `requestAnimationFrame` → `onXRFrame`
  is not recursive in the traditional sense, so TCO is less relevant here.
- **Lazy evaluation** (Haskell): structures are computed on demand. But this
  introduces its own complexity with space leaks.
- **Persistent data structures**: Clojure has them natively. PureScript does not
  by default — you would use a library.

For Manas at current scale (a few hands, a few models): this is not a
performance problem. A Universe with 20 models rebuilt every frame is trivial.
The GC overhead becomes relevant at hundreds of objects per frame. Solve this
when it's measurable, not before.

`monocle-ts` (which you already have) gives you composable lenses for targeted
updates. This doesn't reduce GC pressure but does make nested updates readable:
```typescript
leftHandPinching.set(true)(universe)  // updates only that field, cleanly
```

<!-- YOUR THOUGHTS: -->


---

## V. System Generality — Multi-Platform Architecture

You correctly identified that binding the input system to WebXR hands is a
limitation. The solution is an abstraction layer between hardware and logic.

### The Input Abstraction

Instead of "this is XR hand data," define abstract input events that can
come from any hardware:

```
AbstractInput:
  Pointer (a point or ray in space, with optional pressure/hover state)
  Gesture (a named pattern: Pinch, Grab, OpenPalm, Point)
  Command (a semantic intent: Select, Confirm, Cancel, Undo)
  Spatial (6DOF pose: position + orientation, from controller or head)
```

Each hardware type has an ADAPTER that converts raw hardware input into
AbstractInput:

```
XRHandAdapter:    XRHand → Gesture + Pointer
XRControllerAdapter: XRInputSource → Spatial + Command
MouseAdapter:     MouseEvent → Pointer + Command
KeyboardAdapter:  KeyboardEvent → Command
```

The update function receives AbstractInput, not XR-specific types. This means:
- A keyboard user can navigate the scene with arrow keys
- A mouse user can click and drag objects
- An XR user can grab and move with hands
- All three produce the same Events; update() doesn't know the source

### The Render Abstraction

Currently rendering is bound to `XRView`. To support a spectator view
(watching someone else's XR session on a flat screen), the render function
needs an abstract camera:

```typescript
type Camera = {
  projectionMatrix: Mat4
  viewMatrix: Mat4
  viewport: { x: number, y: number, width: number, height: number }
}
```

An XR session produces one Camera per eye. A desktop session produces one
Camera for the whole screen. The render function accepts `Camera[]` — array
of viewports — and renders the same Universe for each. The Universe is the
same regardless of who is watching.

### The Session Abstraction

Taking this further: a "session" is any channel through which a Universe is
experienced. An XR session, a desktop preview session, and a recorded playback
session are all sessions — they differ only in how they produce Cameras and
consume Events.

<!-- YOUR THOUGHTS: -->


---

## VI. Matrix Math — What Happens Where

You raised the GPU question and your instinct is right, but there's a
precision that matters here.

### What the Vertex Shader Does

```glsl
gl_Position = u_projection * u_view * u_model * vec4(a_position, 1.0);
```

This runs ON THE GPU, for EVERY VERTEX, in parallel. For a cube with 36
vertices, this is 36 matrix-vector multiplications happening simultaneously.
This is incredibly fast. The multiplication here is MATRIX × VECTOR.

### What the CPU Must Do

`u_projection`, `u_view`, and `u_model` are UNIFORMS — they are values
uploaded FROM the CPU to the GPU before drawing. The GPU cannot compute them
on its own from your object's position, rotation, and scale values without
you providing the matrix.

So: for every object in the scene, you must compute its 4×4 model matrix
on the CPU (from position, rotation, scale), then upload it as `u_model`.
The GPU then multiplies that matrix by each vertex.

The computation chain:
```
CPU: position + rotation + scale → Mat4 model matrix (one per object)
CPU → GPU: upload model matrix as uniform
GPU: model matrix × vertex position → clip space position
```

### What Should Live Where

**On the GPU (stay there):**
- The final matrix-vector multiplication in the vertex shader ✓
- Surface shading calculations in the fragment shader ✓
- Color computation from uniforms ✓

**On the CPU (your TypeScript):**
- Building the model matrix from transform (TRS composition)
- Building the view matrix from camera position
- Building the projection matrix from FOV and aspect ratio
- Composing these three matrices into one combined matrix (optimization:
  instead of three matrix uploads per draw call, pre-multiply them on CPU
  and upload one combined MVP matrix)

### On Learning the Math vs Using a Library

Your instinct to learn and implement is the right one given that understanding
is the goal. The matrices you need to understand:

- **Translation matrix**: positions an object at (x, y, z) in world space.
  Straightforward — the fourth column holds tx, ty, tz.
- **Scale matrix**: diagonal matrix with sx, sy, sz on the diagonal.
- **Rotation matrices**: derived from sin/cos of an angle around each axis.
  The geometry behind these: a rotation matrix is a description of where
  each axis ends up after the rotation. Column 0 says "where does X go?"
  Column 1 says "where does Y go?" Column 2 says "where does Z go?"
- **Perspective projection**: this is the hardest one. It creates the illusion
  of depth by dividing x and y by z. The near/far planes, FOV, and aspect
  ratio all appear in this matrix. Understanding it requires understanding
  homogeneous coordinates — the reason we use 4×4 matrices for 3D.
- **View matrix**: the inverse of the camera's transform. "Where is the
  camera?" becomes "rotate and translate the world so the camera is at origin."

The XR headset provides the view and projection matrices via `XRView.projectionMatrix`
and `XRView.transform`. For XR, you don't need to build these yourself — the
headset generates them. What you DO need is the model matrix per object.

<!-- YOUR THOUGHTS: -->


---

## VII. The Discipline Beyond Architecture

You said: "There is some discipline that goes beyond software architecture,
beyond paradigms, beyond languages. I don't have a clear definition of what
I want here."

What you are pointing toward has several names depending on the tradition:

**Mathematical Aesthetics**
The quality of economy, precision, and elegance that good mathematics has.
A mathematical proof is beautiful when it is minimal — no wasted steps — and
when the structure of the proof reveals why the result is true, not just that
it is. Good programs have this quality: the structure reveals the reasoning.

**Denotational Semantics**
The discipline of asking "what does this program MEAN, mathematically?"
before asking "what does this program DO, computationally?" Each type has a
denotation (a mathematical object it represents). Each function has a
denotation (a mathematical function). The program is correct when its
denotation matches the intended meaning.

**Type Theory**
The study of types as propositions. A function `f :: A → B` is a proof that
if A is true, B follows. A program that compiles is a proof that the types
are consistent. This is the Curry-Howard correspondence. Under this view,
writing code is writing proofs. A type error is not a syntax problem —
it is a logical inconsistency.

**Correctness by Construction**
Designing a system so that incorrect states cannot be expressed. If you
cannot write incorrect code without a type error, the program is correct by
construction. This is stronger than testing — tests check cases; types
check all cases simultaneously.

**The Aesthetic Element**
Beyond correctness: programs that feel inevitable. A function signature that
could not be anything else. A type that captures exactly the right amount of
information — no more, no less. The sense that the code is describing the
problem, not just solving it.

This is what you're reaching for. It is a practice, not a technique. It
develops through: studying mathematics (especially abstract algebra and type
theory), reading Haskell and the FP literature, writing and rewriting the
same function until it cannot be simplified further, and asking always
"what does this mean?" before "how does this work?"

The name closest to what you're describing might be: **programming as mathematics**
— the pursuit of programs that are mathematical objects, not just instructions
for machines.

<!-- YOUR THOUGHTS: -->


---

*Add comments anywhere. Bring questions back to the conversation.*
