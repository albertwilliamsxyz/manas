# Manas — Architecture Overview

## Vision

Manas is an immersive AR/VR environment whose purpose is to amplify human cognition. The user expresses and experiments with any model of the world they can imagine inside a general framework that lets ideas run — or be evaluated — in a live environment. The program is not "built"; it is **discovered**: a computable process that, when executed, produces the desired experience.

---

## Guiding Philosophy

The architecture is grounded in **Category Theory**:

| CT concept | Code mapping |
|------------|-------------|
| Object (type) | TypeScript type / interface |
| Morphism (function) | Pure function `A → B` |
| Composition | `pipe(f, g, h)` from fp-ts |
| Functor | `Option`, `Either`, `Array` maps |
| Product type | `{ field: A; field: B }` |
| Sum type (coproduct) | Discriminated union (`\| tag`) |
| Identity morphism | `identity` from fp-ts |

Every piece of state is an **object**. Every transformation is a **morphism**. The system evolves by composing morphisms, never by mutation.

---

## Layers

The application is split into conceptual layers that mirror the rendering pipeline and the information flow from hardware to perception:

```
┌─────────────────────────────────────────────────────┐
│  0. Navigator Layer                                 │
│     DOM access — resolves the canvas element        │
├─────────────────────────────────────────────────────┤
│  1. Core (Nuclear) Layer                            │
│     High-level policies, entities, gesture FSM,    │
│     models registry, scene graph                   │
├─────────────────────────────────────────────────────┤
│  2. Graphics Layer                                  │
│     WebGL2 — shaders, VAOs, buffers, uniforms       │
├─────────────────────────────────────────────────────┤
│  3. Input Layer                                     │
│     WebXR hand tracking, joint poses, gestures     │
├─────────────────────────────────────────────────────┤
│  4. Display Layer                                   │
│     XR frame loop, per-eye projection, framebuffer │
└─────────────────────────────────────────────────────┘
```

### Layer responsibilities

#### 0 — Navigator Layer
Resolves browser globals (`document`, `navigator`) and wraps them in `Option` so the rest of the code never handles `null` directly.

#### 1 — Core (Nuclear) Layer
Contains:
- The **Universe** — the single root state object.
- The **Models** registry — a map of `modelId → { vertices, geometry }`.
- The **Entities** list — `EntityId[]` that acts as the scene graph roster.
- The **NuclearState** — a map of `EntityId → EntityDetails` (position, rotation, scale, model reference).
- The **Gesture FSM** — current state + timestamp of last transition.

Nothing in this layer knows about WebGL. It is pure logic and pure types.

#### 2 — Graphics Layer
Owns all WebGL2 objects:
- `WebGL2RenderingContext`
- Compiled shaders & linked program
- Per-entity VAO + buffer
- Uniform locations (`u_projection`, `u_view`, `u_model`, `u_color`)

Reads from the Core layer to know *what* to draw and *where*, but never writes back to it.

#### 3 — Input Layer
Processes `XRInputSource.hand` joint poses each frame:
- Fills `Float32Array` vertex buffers for left/right hands.
- Measures finger-tip distances to detect gestures (e.g. pinch).
- Emits events / state transitions into the Core layer.

#### 4 — Display Layer
Drives the `XRSession` render loop:
- Requests the `XRFrame`.
- Reads the `XRViewerPose` and iterates over views (one per eye in stereo).
- Sets the per-eye projection and view uniforms.
- Delegates rendering to the Graphics layer.
- Schedules the next frame.

---

## Data flow per tick

```
XRFrame
  │
  ▼
Input Layer      ─── joint poses ──▶  Core Layer (Gesture FSM, entity updates)
                                              │
                                              ▼
                                       Graphics Layer (uniform updates, draw calls)
                                              │
                                              ▼
                                       Display Layer (framebuffer swap, next frame)
```

---

## State model (target)

```typescript
// Primitive aliases — one abstraction layer above TypeScript primitives
type Scalar   = number
type EntityId = string
type ModelId  = string

// Algebraic geometry types
type Vec2 = [Scalar, Scalar]
type Vec3 = [Scalar, Scalar, Scalar]
type Vec4 = [Scalar, Scalar, Scalar, Scalar]
type Mat4 = [
  Scalar, Scalar, Scalar, Scalar,
  Scalar, Scalar, Scalar, Scalar,
  Scalar, Scalar, Scalar, Scalar,
  Scalar, Scalar, Scalar, Scalar,
]

// Models — loaded once, never mutated
type Model = {
  readonly modelId:    ModelId
  readonly vertices:   Float32Array
  readonly indices?:   Uint16Array
}

// Core entity state
type EntityDetails = {
  readonly modelId:  ModelId
  readonly position: Vec3
  readonly rotation: Vec3   // Euler angles (radians)
  readonly scale:    Vec3
}

// Gesture finite-state machine
type GestureKind = 'idle' | 'pinch' | 'grab' | 'point'
type GestureState = {
  readonly kind:          GestureKind
  readonly startedAt:     number        // DOMHighResTimeStamp
}

// Layer states
type NuclearState = {
  readonly entities:   Map<EntityId, EntityDetails>
  readonly gesture:    { left: GestureState; right: GestureState }
}

type GraphicsState = {
  readonly entities: Map<EntityId, { vao: WebGLVertexArrayObject; vertexCount: number }>
}

// The single root — the Universe
type Universe = {
  readonly models:       Map<ModelId, Model>
  readonly entityIds:    EntityId[]
  readonly nuclearState: NuclearState
  readonly graphicsState: GraphicsState
}
```

---

## Transformation pipeline (per-entity rendering)

```
NuclearState.EntityDetails
  │  position, rotation, scale
  │
  ▼
composeModelMatrix(position, rotation, scale)
  │  M_total = T × Rz × Ry × Rx × S
  │
  ▼
gl.uniformMatrix4fv(u_model, …)          ← set on GPU
gl.uniformMatrix4fv(u_view, …)           ← from XRView.transform.inverse.matrix
gl.uniformMatrix4fv(u_projection, …)     ← from XRView.projectionMatrix
  │
  ▼
Vertex Shader: gl_Position = u_projection × u_view × u_model × vec4(a_position, 1.0)
```

---

## Multiplayer / sync (planned)

The **NuclearState** is the minimal synchronisation unit:
- On session join: receive the full `NuclearState + Models` and reconstruct locally.
- During session: broadcast **events** (not full state) using an event-sourcing / CRDT approach so updates are idempotent across all clients.
- The Graphics and Display layers are always derived locally from the authoritative NuclearState — they are never synced.

---

## Architecture Decision Records

Individual rationale documents live in [`docs/adr/`](./adr/):

| # | Decision |
|---|---------|
| [001](./adr/001-typescript.md) | TypeScript over plain JavaScript |
| [002](./adr/002-fp-ts.md) | Functional programming with fp-ts |
| [003](./adr/003-webgl2.md) | WebGL2 as the graphics API |
| [004](./adr/004-webxr.md) | WebXR for immersive AR/VR |
| [005](./adr/005-layered-architecture.md) | Layered (nuclear / graphics / input / display) architecture |
| [006](./adr/006-category-theory.md) | Category theory as the design philosophy |
| [007](./adr/007-vite.md) | Vite + basic-ssl as build and dev server |
| [008](./adr/008-immutable-state.md) | Immutable, functional state management |
