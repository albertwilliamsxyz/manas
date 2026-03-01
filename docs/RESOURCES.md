# Manas — Resource Lifecycle & Context Encapsulation

> Add your comments with <!-- -->. This document has no code, only principles.

---

## I. The Verbosity Question

You asked: is it okay to declare each step — create, initialize, configure,
build, load, start — individually, even when verbose?

Yes. Verbose is correct here. Here is why.

Each step in the lifecycle is a different kind of operation with a different
failure mode and a different reversibility. Conflating two steps into one
function saves lines of code but destroys the ability to:

- **Fail precisely**: if creation and initialization are one function, you
  don't know which part failed, how to clean up, or whether a retry is safe.
- **Compose independently**: you may want to create a resource now but
  initialize it later when you have the data. Fused functions forbid this.
- **Skip safely**: if you don't need initialization step 3 for a particular
  use case, you simply don't call it. If steps 2 and 3 are fused, you can't.
- **Test in isolation**: you can test that creation produces a valid resource
  independently of whether initialization works.

The cost of verbosity is lines of code and the discipline of calling things
in the right order. The cost of conflation is silent errors, hidden coupling,
and debugging the interior of a fused function.

Your instinct — "even if it's verbose it's safe" — is the correct one.
Verbosity at the call site is clarity. Brevity at the call site is often
hiding complexity somewhere else.

The codebase you're building will be read by you months from now. A reader
who sees:
```
const buffer = createBuffer(gl)
initializeBuffer(gl, buffer, data, gl.STATIC_DRAW)
configureBuffer(gl, buffer, positionLocation)
```
understands each operation. A reader who sees:
```
const buffer = makeVAO(gl, data, positionLocation)
```
understands none of the steps or their constraints.

<!-- YOUR THOUGHTS: -->


---

## II. The Problem: Dependent Resources

Resources in graphics programming form a dependency graph:

```
Canvas
  └── WebGL2RenderingContext (gl)
        ├── VertexShader
        │     └── (requires VERTEX_SHADER_SOURCE string)
        ├── FragmentShader
        │     └── (requires FRAGMENT_SHADER_SOURCE string)
        ├── Program
        │     ├── (requires VertexShader)
        │     ├── (requires FragmentShader)
        │     └── UniformLocations
        │           └── (requires Program)
        ├── Buffer (for each hand, cube, etc.)
        │     └── (requires gl)
        └── VertexArrayObject
              ├── (requires gl)
              ├── (requires Buffer)
              └── (requires attribute location from Program)
```

Every node requires its parent. This creates a sequencing obligation:
if you call `gl.getAttribLocation(program, 'a_position')` before the program
is linked, you get -1 and the binding is silent but wrong.

The question is: how do you enforce this sequencing in the type system, or
at least make it impossible to ignore?

<!-- YOUR THOUGHTS: -->


---

## III. The Capability Pattern

The fundamental answer: **a value that exists is proof that its dependencies
exist**. This is the capability pattern.

`gl: WebGL2RenderingContext` is not just a reference to a WebGL context.
It is a CAPABILITY TOKEN — the proof that the graphics subsystem was
successfully initialized. A function that accepts `gl` as a parameter is
saying: "I require graphics capability." A function that does not accept it
cannot touch the GPU.

This is already what you do. The insight is to think of types not as data
shapes but as capabilities and proofs:

- `WebGL2RenderingContext` = "I can talk to the GPU"
- `WebGLProgram` = "a shader program has been compiled and linked"
- `WebGLBuffer` = "GPU memory has been allocated for this data"
- `WebGLVertexArrayObject` = "vertex format and buffer bindings are recorded"
- `XRSession` = "an XR hardware connection is active"
- `XRReferenceSpace` = "a spatial coordinate system has been established"

When a function requires `(gl, program, buffer)`, the type signature is
telling you exactly what capabilities are needed. You cannot call it without
having successfully created all three.

The limitation in TypeScript (vs Haskell): nothing prevents you from passing
a `WebGLProgram` that was created with a different `gl` context than the one
you're passing alongside it. The type says "some program" not "this program,
created by this context." Linear types (Rust) or session types (exotic Haskell)
would enforce this. TypeScript cannot. The convention compensates: suffix
resources with the context that created them if you ever have multiple contexts.

<!-- YOUR THOUGHTS: -->


---

## IV. The Context Object — Collecting Capabilities

When a group of resources are always used together, collect them into a context
object. This is not a global — it is a RECORD OF PROVEN CAPABILITIES passed
explicitly wherever needed.

For Manas, the graphics initialization phase produces a single record:

```
RenderContext = {
  gl:               the capability to draw
  program:          a compiled shader
  uniformLocations: handles into the shader's variables
  buffers:          pre-allocated GPU memory regions
  vaos:             recorded vertex format descriptions
  geometryRegistry: a registry of uploaded geometries
}
```

This object is the PRODUCT of a successful initialization. It carries the
proof that all the steps succeeded. Functions that need to draw accept
`RenderContext`, not `gl` alone — because they need more than just the GPU
capability; they need the compiled program, the buffers, everything.

The alternative — passing `gl`, `program`, `positionLocation`, `buffer`, ...
as separate parameters — is correct but verbose at the call site. The context
object trades a flat parameter list for a single, named, cohesive structure.

The design question is: what belongs in one context? The answer: things that
are created together, live together, and die together. If you need a buffer
in every function that needs `gl`, that buffer belongs in the same context.
If you only need a buffer in two functions, pass it separately.

<!-- YOUR THOUGHTS: -->


---

## V. The Builder Pattern for Sequential Initialization

When initialization has many required steps in a strict order, the builder
pattern makes the correct order explicit and makes incomplete initialization
a type error.

Conceptually:

```
Step 1: create context from canvas → CanvasContext
Step 2: compile shaders with CanvasContext → ShadersContext
Step 3: link program with ShadersContext → ProgramContext
Step 4: get uniform locations with ProgramContext → UniformContext
Step 5: create buffers with UniformContext → fully initialized RenderContext
```

Each step produces a different type. The next step requires the output of
the previous. You cannot call step 3 before step 2 because step 3 requires
`ShadersContext`, which only step 2 produces. The type system enforces the
order.

In TypeScript this is verbose (you would need 5 intermediate types) but the
concept is sound. A simpler approximation: use a single `build()` function
that runs ALL initialization steps in order, fails at the first error with
full context about which step failed, and returns a single `RenderContext`.
The transparency of the individual steps is preserved inside `build()` while
the call site is a single expression.

The `Either` chaining your code already does — `pipe(create(...), E.chain(initialize(...)))` —
is exactly this pattern. You're doing it right. The improvement is to name
the intermediate states.

<!-- YOUR THOUGHTS: -->


---

## VI. What to Allocate and What to Create

You mentioned not liking "allocate" because it's concrete — too close to C.
This is a fair aesthetic position. Here is a framework for when each word fits:

**allocate** — use only when you are explicitly claiming a region of memory
for future use, before knowing what data will go in it. `gl.bufferData` with
`gl.DYNAMIC_DRAW` and zeroed data is allocation. `new Float32Array(75)` is
allocation. The word is appropriate when the point is "reserving space."

**create** — use for creating a new resource object (handle) without claiming
memory for data yet. `gl.createBuffer()` creates a handle; it doesn't allocate
GPU memory. The memory comes with `gl.bufferData`.

**initialize** — appropriate for `gl.bufferData` called for the first time.
You are initializing the buffer's content and marking its usage intent.

**update** — appropriate for `gl.bufferSubData`. You are updating content
that was already initialized. This is the distinction between first write
(initialize) and subsequent writes (update).

So the sequence for a hand buffer:
```
create:     gl.createBuffer()
initialize: gl.bufferData(..., new Float32Array(75), gl.DYNAMIC_DRAW)
update:     gl.bufferSubData(...) — called every frame with new joint positions
destroy:    gl.deleteBuffer()
```

This vocabulary is precise about what phase of the resource lifecycle you're in.
You can avoid "allocate" entirely — use "initialize" for first-write and
"update" for subsequent writes. The memory semantics are implied by
`gl.DYNAMIC_DRAW` vs `gl.STATIC_DRAW`.

<!-- YOUR THOUGHTS: -->


---

## VII. The Initialization Sequence as a Protocol

The full sequence for Manas initialization, with the correct word at each step:

```
1. GET        application canvas from DOM
2. CREATE     WebGL2 context from canvas
3. CONFIGURE  depth test, viewport defaults
4. CREATE     vertex shader object
5. INITIALIZE vertex shader object with source and compile
6. CREATE     fragment shader object
7. INITIALIZE fragment shader object with source and compile
8. CREATE     shader program
9. INITIALIZE program by attaching shaders and linking
10. QUERY     uniform locations from linked program
11. QUERY     attribute locations from linked program
12. CREATE    buffer for left hand joints
13. INITIALIZE buffer with zeroed Float32Array, DYNAMIC_DRAW
14. CREATE    VAO for left hand joints
15. CONFIGURE VAO: bind buffer, set attrib pointer, enable array
16. [repeat 12-15 for left hand skeleton, right hand, cube, etc.]
17. BOOT      the application: wire the button click
18. START     the XR session (happens on user gesture)
19. QUERY     reference space from session
20. LOOP      requestAnimationFrame → onXRFrame, forever
```

Step types:
- GET, QUERY: reading from existing systems, usually safe, may return null
- CREATE: GPU resource allocation, can fail (context lost)
- INITIALIZE: first data write, sets usage mode
- CONFIGURE: adjusting behavior/parameters on existing resources  
- BOOT: wiring event listeners and application entry points
- START: beginning a stateful process (sessions, loops)
- LOOP: ongoing execution

You cannot do step 10 before step 9. You cannot do step 14 before step 12.
The dependency order IS the correctness. Naming each step makes this visible.

<!-- YOUR THOUGHTS: -->

---

*Comment anywhere. These are principles, not prescriptions.*
