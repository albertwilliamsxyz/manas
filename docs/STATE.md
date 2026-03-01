# Manas — State Design, Structural Sharing & Optimization

> Add your comments with <!-- -->. This document explores state at depth.

---

## I. What State Is — A Precise Definition

State is everything that varies between two moments in a program's execution
AND affects the program's behavior going forward.

This definition has two conditions joined by AND. Both must be true:
- A constant is not state: it varies nowhere.
- A log file is not state (in this sense): it affects nothing going forward.
- The current joint positions: they vary AND affect the next render. State.
- The compiled shader program: once created it doesn't change (outside of hot-reload).
  It belongs to the resource context, not the Universe. Not state.

The cleanest test: if the program crashed and you needed to restore it to the
exact same moment, what values would you need to save? That list is your state.
For Manas: joint positions, entity transforms, loaded geometries, gesture flags.
Not: the shader program (recompilable), the WebGL context (recreatable from canvas),
the XR session (recreated by user action).

This distinction matters because the Universe should contain ONLY state, not
resources. Resources are created once and threaded through as context.
State belongs in the Universe and flows through the update function as values.

<!-- YOUR THOUGHTS: -->


---

## II. Identifying State in Your Current Code

Walk through `main.ts` and ask, for each variable: is this state?

| Variable | State? | Where it should live |
|---|---|---|
| `gl` | No — stable resource | `RenderContext` |
| `program` | No — stable resource | `RenderContext` |
| `leftHandBuffer` | No — stable resource | `RenderContext` |
| `leftHandVAO` | No — stable resource | `RenderContext` |
| `cubePosition` | YES | `Universe.entities[cubeId].transform.position` |
| `cubeRotation` | YES | `Universe.entities[cubeId].transform.rotation` |
| `cubeScale` | YES | `Universe.entities[cubeId].transform.scale` |
| `leftHandVertices` | YES — but ephemeral | `Universe.hands.left.joints` |
| `rightHandVertices` | YES — but ephemeral | `Universe.hands.right.joints` |
| `distanceBetweenLeftHandIndexFingerTipAndThumbTip` | Derived — not state | Computed from `Universe.hands.left.joints` on demand |
| `drawingVertices` | YES — but unimplemented | `Universe.entities[drawingId].strokes` |

Everything marked YES should live in the Universe. Everything marked No
should live in `RenderContext` or be passed as a parameter. Derived values
should not be stored — computed freshly from state each frame, or memoized.

Notice: `distanceBetweenLeftHandIndexFingerTipAndThumbTip` is over-stored.
You compute it, use it once, and then it's gone. It's ephemeral derived state.
The canonical version is: derive it FROM the Universe, do not put it IN the Universe.
But `isPinching: boolean` IS worth storing in the Universe — it's a named,
semantically important derived fact that the rest of the system reads.

<!-- YOUR THOUGHTS: -->


---

## III. Designing the Universe Type — Four Principles Applied

### Principle 1: One truth per fact

Each piece of information appears exactly once in the Universe. If you have
the joint positions in both the Universe AND the GPU buffer, the GPU buffer
is a projection — a copy that the renderer writes from the truth. The truth
lives in the Universe.

This has a concrete consequence: when you want to know where the left index
finger tip is, you look in `Universe.hands.left.joints['index-finger-tip']`.
Never in the GPU buffer (you can't read it back without a round-trip anyway).
Never in a separate variable. Never computed inline each time you need it.
Once. In one place.

### Principle 2: Normalize, except for named derives

Normalization: don't store X if X can be computed from Y (where Y is already
stored). Example: don't store the pinch distance — compute it from joint positions.
The exception: if the derived value has a name that means something to the domain,
store it. `isPinching` is a domain concept. Storing it makes the universe legible.
Not storing it means every consumer must know how to compute it. The tradeoff:
slightly redundant storage for much greater clarity.

A rough rule: store derived state if and only if it is named and meaningful in
the vocabulary of the problem domain. "Whether the user is pinching" is domain
vocabulary. "The Euclidean distance between thumb and index finger" is not.

### Principle 3: Make illegal states unrepresentable

The type of a value should exclude invalid combinations. Examples:

Bad: `{ isTracked: boolean, jointPositions: Float32Array }` — you can have
`isTracked: false` but `jointPositions` of a valid past position. Is it stale?
Unknown.

Good: `type Hand = { joints: JointConfiguration, isPinching: boolean } | null`
— null means not tracked. Non-null means tracked. You cannot have a tracked
hand with missing joints or an untracked hand with a gesture.

Bad (in TypeScript): generic string where only certain strings are valid.
`handedness: string` allows `'foot'`. Use `'left' | 'right'`.

Good: `type Handedness = 'left' | 'right'`

Bad: `loadedDocuments: Document[]` and `loadingDocuments: string[]` separately,
allowing the same URL to appear in both.

Good: `type DocumentState = { status: 'loading', url: string } | { status: 'loaded', document: Document } | { status: 'error', url: string, error: Error }`

Each case is a distinct state. The type makes mixed states impossible.

### Principle 4: Flat over nested

Every level of nesting requires one more step to update. In an immutable
system with spread-based updates, deeply nested structures are verbose to
modify. Prefer a flat structure where possible.

Compare:
```
// Deep (verbose to update)
universe.scene.spatial.entities.models[id].transform.position

// Flat (cleaner)
universe.entities[id].position
```

The geometry data (vertex arrays) is the exception — it is large and not changed
frequently. It belongs in its own registry keyed by geometry ID, not embedded
in every entity.

<!-- YOUR THOUGHTS: -->


---

## IV. A Proposed Minimal Universe for Manas

Based on the MVP (3D models, drawings, documents, hands):

```
Universe = {
  // Entities — everything that exists in the scene
  entities: Map<EntityId, Entity>

  // Spatial organization — which entities are in which scene
  // and what order they appear in the scene graph
  scene: {
    id: SceneId
    name: string
    entityIds: EntityId[]  // ordered list of all entities in this scene
  }

  // Hand tracking state — null when not tracked
  hands: {
    left:  Hand | null
    right: Hand | null
  }

  // Geometry registry — shared vertex data, referenced by entities
  // Lives in Universe because it changes when documents/models are loaded
  geometries: Map<GeometryId, GeometryData>

  // Application mode — what the user is currently doing
  mode: AppMode
}

Entity = ObjectEntity | DocumentEntity | DrawingEntity | RelationEntity

ObjectEntity = {
  kind: 'object'
  id: EntityId
  geometryId: GeometryId
  transform: Transform
  concept: string | null    // semantic label
  relations: Relation[]
}

DocumentEntity = {
  kind: 'document'
  id: EntityId
  url: string
  loadState: DocumentLoadState
  transform: Transform      // position in space
  size: [width, height]     // display dimensions in meters
}

DrawingEntity = {
  kind: 'drawing'
  id: EntityId
  strokes: Stroke[]
  transform: Transform
}

Hand = {
  joints: JointConfiguration
  isPinching: boolean
  isGrabbing: boolean
  gesture: NamedGesture | null
}

AppMode =
  | { type: 'viewing' }
  | { type: 'drawing', activeStroke: Stroke | null }
  | { type: 'moving', entityId: EntityId, grabOffset: Vec3 }
  | { type: 'relating', fromEntityId: EntityId }
```

Each `AppMode` variant represents a distinct interaction state. The universe
knows what the user is doing, not just what exists. This is how modes work:
the mode is state, not implicit behavior.

<!-- YOUR THOUGHTS: -->


---

## V. Structural Sharing — What It Is and Why It Matters

### The Naive Copy Problem

When you write `universe = { ...universe, hands: newHands }`, JavaScript creates
a new object with the same references as `universe`, except `hands` is replaced.
This is O(1) for the top level — just a shallow copy of the object's keys.

But if you need to update a deeply nested field:
```typescript
// Updating one entity's transform position — the naive way
universe = {
  ...universe,
  entities: new Map([
    ...universe.entities,
    [entityId, {
      ...universe.entities.get(entityId)!,
      transform: {
        ...universe.entities.get(entityId)!.transform,
        position: newPosition
      }
    }]
  ])
}
```

At the top level, this copies only the `entities` key. But it creates:
- A new outer object
- A new Map (copying all entries)
- A new entity object
- A new transform object

The rest of the entities are shared (their references are copied, not their
data). This is structural sharing: unchanged parts share memory with the
previous version. Only the changed path from root to the modified value is
new.

### The Structural Sharing Property

A persistent data structure has structural sharing when:
- Updating a value creates a new root AND a new path from root to the changed node
- All other branches of the previous version remain intact and shared

This is what Clojure's persistent vectors do automatically. They use a
32-ary tree structure where each update is O(log₃₂ n) — essentially O(1) in
practice because depths rarely exceed 2-3 levels for typical collection sizes.

JavaScript's `Map` copied into a new Map is O(n) — it copies all entries even if
only one changed. This is NOT structural sharing.

### What You Can Do In JavaScript

Three options, in order of increasing performance efficiency:

**Option 1: Spread and Map copy (what you have now)**
Fast enough for small universes. Start here. Profile before changing.
GC pressure: creates many short-lived objects per frame.

**Option 2: `immer` — structural sharing via copy-on-write proxy**
`produce(universe, draft => { draft.hands.left = newHand })` looks like mutation,
but immer creates a structurally shared new version using JavaScript Proxy.
Near-zero boilerplate. Modest overhead from the proxy. Works well with `monocle-ts`.

**Option 3: `monocle-ts` lenses — explicit structural sharing**
`handLeftIsLens.set(newHand)(universe)` — a lens describes the path to a field
and constructs the minimally-changed new Universe. No proxy overhead. More
verbose to set up than immer. More transparent about what's happening.
Lenses compose: a lens to the hand × a lens to isPinching = a lens to
`universe.hands.left.isPinching` — you can navigate the whole structure this way.

<!-- YOUR THOUGHTS: -->


---

## VI. Insights for Future-You Working on Performance

These are not things to do now. They are things to know so that when the
problem appears, you recognize it quickly.

### Insight 1: The Frame Budget

On a Meta Quest 3 (2023 hardware), you have ~11ms per frame at 90fps.
WebXR on a mobile GPU is significantly more constrained than a desktop.
The breakdown:
- Input reading: ~0.1ms (cheap)
- Update (pure TypeScript): ~0.5-2ms depending on entity count
- Buffer uploads (CPU→GPU): ~0.5-3ms depending on data volume
- Render (GPU): ~3-8ms depending on geometry complexity

The GC pause is the wildcard. A major GC pause on mobile can cost 5-20ms —
this drops frames. GC pressure comes from allocation inside the hot path.

### Insight 2: Allocation Hotspots to Watch

The frame callback should eventually allocate nothing. Every `new Float32Array()`,
every `{ ...spread }`, every `new Map()` inside `onXRFrame` is a GC candidate.
When you're ready to optimize:

- Preallocate all Float32Arrays at startup. Reuse them by writing into them.
- Keep a "previous Universe" and diff only changed fields. Update in place if
  needed (sacrificing immutability for performance at a specific, profiled bottleneck).
- Use typed arrays (Float32Array, Int32Array) over regular arrays — they are
  allocated in a separate heap that GC touches less frequently.
- Consider a double-buffer Universe: two universe objects you swap between frames,
  rather than creating new objects each frame.

### Insight 3: The Immutability / Performance Tradeoff

Immutability is not free. It costs GC pressure. The tradeoff is:
- Immutability → correctness, debuggability, replayability, testability
- Mutability → performance, lower GC pressure, cache-friendliness

The professional answer: start immutable. Profile when you observe frame drops.
Introduce targeted mutation ONLY at the measured bottlenecks, ONLY after
verifying your pure system is correct. Premature optimization of an incorrect
system produces an optimized incorrect system.

The insight for future-you: if you ever add mutation for performance, isolate
it behind an interface that still looks pure to the outside. The update function
signature `(Universe, Event) → Universe` can be maintained even if the
implementation reuses the universe object internally. The callers are unchanged.
This is why interfaces matter more than implementations.

### Insight 4: Normalization as a Performance Strategy

If you store entity data as `Map<EntityId, Entity>`, looking up one entity is O(1).
If you store it as `Entity[]`, looking up by ID is O(n). This matters when you
have 100+ entities. Keep the registry as a Map (or as a normalized object with
ID keys) so lookups are fast.

Separate hot data from cold data:
- Hand joint positions change every frame → hot, keep close to the render path
- Entity conceptual labels (`concept: string`) change rarely → cold, fine anywhere
- Geometry vertex data never changes after load → cold, cache aggressively

### Insight 5: When to Consider PureScript

PureScript's strict evaluation (no laziness) maps more predictably to
performance than Haskell. Its FFI (foreign function interface) lets you call
WebGL cleanly. Its type system forces you to handle effects explicitly.

What PureScript gives you:
- Exhaustive typeclasses (things TypeScript can't enforce)
- Real algebraic data types with efficient pattern matching
- Tail-call optimization across all recursive functions
- A clean effect monad (`Aff`, `Effect`) with no ambiguity

What PureScript costs you:
- A steeper learning curve
- A smaller ecosystem
- Compilation is slower
- Interop with WebXR types requires writing FFI bindings

The right time to consider PureScript: after you have a working TypeScript
version and you know exactly what you want the program to be. Rewrite when
you understand the problem completely, not before.

<!-- YOUR THOUGHTS: -->


---

*Comment anywhere. The future-you insight section is especially worth annotating.*
