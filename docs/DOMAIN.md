# Domain Knowledge

Reference material for every domain concept active in the project. The goal is that reading this document gives you enough context to work on any layer without needing external references open.

---

## Table of Contents

1. [WebXR lifecycle](#1-webxr-lifecycle)
2. [Hand tracking](#2-hand-tracking)
3. [Gesture recognition](#3-gesture-recognition-pinch-fsm)
4. [WebGL2 rendering pipeline](#4-webgl2-rendering-pipeline)
5. [The MVP matrix stack](#5-the-mvp-matrix-stack)
6. [Coordinate systems](#6-coordinate-systems)
7. [GLSL shader language](#7-glsl-shader-language)
8. [Algebraic type system (TypeScript)](#8-algebraic-type-system-typescript)
9. [Functional programming patterns](#9-functional-programming-patterns)

---

## 1. WebXR lifecycle

```
navigator.xr
  │
  ├─ isSessionSupported('immersive-ar')  →  boolean
  │
  └─ requestSession('immersive-ar', { optionalFeatures: ['hand-tracking'] })
       │
       └─ XRSession
            │
            ├─ updateRenderState({ baseLayer: new XRWebGLLayer(session, gl) })
            │
            ├─ requestReferenceSpace('local')  →  XRReferenceSpace
            │
            └─ requestAnimationFrame(callback)
                 │
                 └─ XRFrameRequestCallback(time: DOMHighResTimeStamp, frame: XRFrame)
                      │
                      ├─ frame.getViewerPose(referenceSpace)  →  XRViewerPose
                      │    └─ .views: XRView[]  (one per eye)
                      │         ├─ .projectionMatrix: Float32Array (4×4)
                      │         └─ .transform.inverse.matrix: Float32Array (4×4)  ← view matrix
                      │
                      ├─ frame.getJointPose(jointSpace, referenceSpace)  →  XRJointPose
                      │    └─ .transform.position: { x, y, z }
                      │
                      └─ session.requestAnimationFrame(callback)  ← next frame
```

### Key rules

- `gl.makeXRCompatible()` must be awaited **before** creating `XRWebGLLayer`.
- `XRSession.requestAnimationFrame` is not `window.requestAnimationFrame` — it is driven by the headset display.
- `frame.getJointPose` returns `undefined` when a joint is occluded or not tracked; always guard with `if (!jointPose) continue`.

---

## 2. Hand tracking

The WebXR Hand Input API reports **25 joints per hand** in the local reference space.

### Joint hierarchy

```
Wrist (0)
├─ Thumb
│   ├─ thumb-metacarpal (1)
│   ├─ thumb-phalanx-proximal (2)
│   ├─ thumb-phalanx-distal (3)
│   └─ thumb-tip (4)
├─ Index finger
│   ├─ index-finger-metacarpal (5)
│   ├─ index-finger-phalanx-proximal (6)
│   ├─ index-finger-phalanx-intermediate (7)
│   ├─ index-finger-phalanx-distal (8)
│   └─ index-finger-tip (9)
├─ Middle finger
│   ├─ middle-finger-metacarpal (10)
│   ├─ middle-finger-phalanx-proximal (11)
│   ├─ middle-finger-phalanx-intermediate (12)
│   ├─ middle-finger-phalanx-distal (13)
│   └─ middle-finger-tip (14)
├─ Ring finger
│   ├─ ring-finger-metacarpal (15)
│   ├─ ring-finger-phalanx-proximal (16)
│   ├─ ring-finger-phalanx-intermediate (17)
│   ├─ ring-finger-phalanx-distal (18)
│   └─ ring-finger-tip (19)
└─ Pinky finger
    ├─ pinky-finger-metacarpal (20)
    ├─ pinky-finger-phalanx-proximal (21)
    ├─ pinky-finger-phalanx-intermediate (22)
    ├─ pinky-finger-phalanx-distal (23)
    └─ pinky-finger-tip (24)
```

### Memory layout

Each hand is stored as a `Float32Array` of 75 floats (`25 joints × 3 axes`):

```
index 0  → wrist.x
index 1  → wrist.y
index 2  → wrist.z
index 3  → thumb-metacarpal.x
...
index 72 → pinky-finger-tip.x
index 73 → pinky-finger-tip.y
index 74 → pinky-finger-tip.z
```

Access pattern:
```typescript
const jointOffset = jointIndex * 3
const x = vertices[jointOffset]
const y = vertices[jointOffset + 1]
const z = vertices[jointOffset + 2]
```

### Skeleton edges

The `HAND_SKELETON_BY_JOINT_INDICES` array encodes the edges of the skeleton as consecutive pairs of joint indices — suitable for `gl.drawElements(gl.LINES, …)`:

```
[0,1, 1,2, 2,3, 3,4,       ← wrist → thumb chain
 0,5, 5,6, 6,7, 7,8, 8,9,  ← wrist → index chain
 …]
```

---

## 3. Gesture recognition — Pinch FSM

A **Finite State Machine** models the gesture lifecycle. This prevents false positives (noisy one-frame detections) and enables timed transitions.

### States

```
idle ──[distance < threshold]──▶ pinch
pinch ──[distance ≥ threshold]──▶ idle
```

### Pinch detection

```typescript
const distance = Math.sqrt(
  (indexTip.x - thumbTip.x) ** 2 +
  (indexTip.y - thumbTip.y) ** 2 +
  (indexTip.z - thumbTip.z) ** 2
)
const PINCH_THRESHOLD = 0.02  // 2 cm in reference space units (metres)
```

### Timed transitions (planned)

Store `startedAt: DOMHighResTimeStamp` in the FSM state. A transition is only confirmed after the gesture has been held for a minimum duration (e.g. 150 ms) — eliminates tremor false positives.

```typescript
type GestureState = {
  kind:      GestureKind
  startedAt: number
}

// Confirm only if held ≥ 150 ms
const isPinchConfirmed = (state: GestureState, now: number) =>
  state.kind === 'pinch' && (now - state.startedAt) >= 150
```

---

## 4. WebGL2 rendering pipeline

```
CPU (JavaScript)                    GPU
─────────────────────────────────   ────────────────────────────────────
Float32Array vertices               Vertex Buffer (VRAM)
         │                                    │
         │ gl.bufferData / bufferSubData       │
         ▼                                    ▼
WebGLBuffer ────── VAO layout ────▶  Vertex Shader (runs per vertex)
                                              │
                                     gl_Position (clip space)
                                              │
                                    Rasterisation (hardware)
                                              │
                                     Fragment Shader (runs per pixel)
                                              │
                                     outColor (RGBA)
                                              │
                                    Framebuffer / Screen
```

### Object lifecycle

```typescript
// 1. Create
const vao    = gl.createVertexArray()
const buffer = gl.createBuffer()

// 2. Bind
gl.bindVertexArray(vao)
gl.bindBuffer(gl.ARRAY_BUFFER, buffer)

// 3. Upload data
gl.bufferData(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)

// 4. Describe layout
gl.vertexAttribPointer(location, 3, gl.FLOAT, false, 0, 0)
gl.enableVertexAttribArray(location)

// 5. Render (each frame)
gl.bindVertexArray(vao)
gl.drawArrays(gl.POINTS, 0, vertexCount)
// or
gl.drawElements(gl.LINES, indexCount, gl.UNSIGNED_SHORT, 0)
```

### Draw call checklist

Before each draw call:
- [ ] `gl.bindVertexArray(vao)` — correct layout
- [ ] `gl.uniformMatrix4fv(modelLocation, false, modelMatrix)` — entity transform
- [ ] `gl.uniformMatrix4fv(viewLocation, false, viewMatrix)` — camera (set once per view)
- [ ] `gl.uniformMatrix4fv(projectionLocation, false, projMatrix)` — projection (set once per view)
- [ ] `gl.uniform4fv(colorLocation, color)` — material colour

---

## 5. The MVP matrix stack

Every vertex in the scene goes through three matrix transformations:

```
World position = Model matrix × local position
Eye position   = View matrix  × World position
Clip position  = Projection matrix × Eye position
```

Combined in the vertex shader:
```glsl
gl_Position = u_projection * u_view * u_model * vec4(a_position, 1.0);
```

### Model matrix

Encodes position (translation), orientation (rotation), and size (scale) of an entity:

```
M = T × Rz × Ry × Rx × S
```

Order matters (matrix multiplication is not commutative). The standard order is:
1. Scale (S) — change size around local origin
2. Rotate (Rx, Ry, Rz) — orient in world space
3. Translate (T) — move to world position

```typescript
const composeModelMatrix = (pos: Vec3, rot: Vec3, scale: Vec3): Mat4 => {
  let m = createScaleMatrix(scale)
  m = multiplyMatrices(createRotationXMatrix(rot[0]), m)
  m = multiplyMatrices(createRotationYMatrix(rot[1]), m)
  m = multiplyMatrices(createRotationZMatrix(rot[2]), m)
  m = multiplyMatrices(createTranslationMatrix(pos), m)
  return m
}
```

### View matrix

Transforms from world space to camera (eye) space. In WebXR this comes directly from:
```typescript
view.transform.inverse.matrix  // XRView → Float32Array (4×4, column-major)
```

Do not compute the view matrix manually in XR — the runtime provides the correct one including head tracking and sensor fusion.

### Projection matrix

Maps from eye space to clip space (NDC). For XR, the runtime provides an asymmetric perspective matrix:
```typescript
view.projectionMatrix  // Float32Array (4×4, column-major)
```

The projection matrix accounts for the physical lens geometry of each specific headset — do not compute it manually in XR.

### Column-major order

WebGL matrices are **column-major**: the first 4 floats are the first **column**, not the first row. This matches GLSL's layout. When constructing matrices in JavaScript, keep this convention:

```
| m0  m4  m8  m12 |
| m1  m5  m9  m13 |
| m2  m6  m10 m14 |
| m3  m7  m11 m15 |
```

The identity matrix:
```typescript
new Float32Array([
  1, 0, 0, 0,  // column 0
  0, 1, 0, 0,  // column 1
  0, 0, 1, 0,  // column 2
  0, 0, 0, 1   // column 3
])
```

---

## 6. Coordinate systems

### WebXR reference space (`'local'`)

- **Origin:** Where the user was when the session started.
- **Y axis:** Up (away from the floor).
- **Z axis:** Towards the user's initial facing direction (negative Z = forward).
- **Units:** Metres.

Hand joint positions and viewer poses are expressed in this space.

### WebGL clip space (NDC)

After applying the projection matrix, coordinates are in **Normalized Device Coordinates**:
- X: −1 (left) to +1 (right)
- Y: −1 (bottom) to +1 (top)
- Z: −1 (near plane) to +1 (far plane)

Everything outside this cube is clipped (not rendered).

### WebGL viewport

`gl.viewport(x, y, width, height)` maps NDC to pixel coordinates within the framebuffer. In XR, each eye gets a different viewport within the shared framebuffer:
```typescript
const viewport = xrGLLayer.getViewport(view)
gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height)
```

---

## 7. GLSL shader language

The project uses **GLSL ES 3.00** (`#version 300 es`), the shader language for WebGL2.

### Type reference

| GLSL type | Description | TypeScript equivalent |
|-----------|-------------|----------------------|
| `float` | 32-bit float | `number` |
| `vec2` | 2-component float vector | `[number, number]` |
| `vec3` | 3-component float vector | `[number, number, number]` |
| `vec4` | 4-component float vector | `[number, number, number, number]` |
| `mat4` | 4×4 float matrix (column-major) | `Float32Array(16)` |
| `sampler2D` | 2D texture sampler | `WebGLTexture` |

### Qualifiers

| Qualifier | Direction | Description |
|-----------|-----------|-------------|
| `in` | CPU → Vertex shader | Per-vertex attribute (was `attribute` in ES 1.00) |
| `uniform` | CPU → Any shader | Same value for all vertices/fragments in a draw call |
| `out` (vertex) | Vertex → Fragment | Interpolated across the triangle (was `varying` in ES 1.00) |
| `out` (fragment) | Fragment → Framebuffer | Final pixel colour |

### Current shaders

**Vertex:**
```glsl
in vec3 a_position;           // fed from VAO / ARRAY_BUFFER
uniform mat4 u_projection;    // set via gl.uniformMatrix4fv
uniform mat4 u_view;
uniform mat4 u_model;
void main() {
  gl_Position = u_projection * u_view * u_model * vec4(a_position, 1.0);
  gl_PointSize = 10.0;        // pixel size for gl.POINTS draw mode
}
```

**Fragment:**
```glsl
precision highp float;
out vec4 outColor;
uniform vec4 u_color;         // set via gl.uniform4fv
void main() {
  outColor = u_color;         // flat colour — no lighting model yet
}
```

---

## 8. Algebraic type system (TypeScript)

### Product types (AND)

Combine multiple fields. Every field must be present.

```typescript
type Vec3 = [number, number, number]              // tuple product
type Entity = { id: EntityId; position: Vec3 }   // record product
```

### Sum types (OR)

One of several variants. Exactly one is active at a time.

```typescript
type GestureKind = 'idle' | 'pinch' | 'grab' | 'point'   // literal union

type AppEvent =
  | { tag: 'EntityAdded'; entityId: EntityId }
  | { tag: 'EntityMoved'; entityId: EntityId; delta: Vec3 }
```

### Type aliases (domain vocabulary)

```typescript
type Scalar   = number    // avoid bare primitives in domain types
type EntityId = string    // distinguishable from arbitrary strings
type ModelId  = string
```

Using `type Alias = primitive` creates a **documentation layer** and makes signatures self-describing. TypeScript does not enforce structural incompatibility between aliases of the same primitive — if stricter separation is needed, use **branded types**:

```typescript
type EntityId = string & { readonly _brand: 'EntityId' }
const mkEntityId = (s: string): EntityId => s as EntityId
```

### Generic types

```typescript
// A computation that may fail
type Fallible<A> = E.Either<Error, A>

// A computation that may be absent
type Maybe<A> = O.Option<A>
```

### `readonly` and immutability

Prefix every field with `readonly` to enforce immutability at the type level:

```typescript
type Universe = {
  readonly models:        Map<ModelId, Model>
  readonly entityIds:     readonly EntityId[]
  readonly nuclearState:  NuclearState
}
```

`readonly` prevents accidental mutation (`universe.entityIds = []` → compile error).

---

## 9. Functional programming patterns

### The morphism pattern

```typescript
// Name captures input type → output type
type EntityTransform = (entity: EntityDetails) => EntityDetails

// Pure — no side effects, no global reads
const translate = (delta: Vec3): EntityTransform =>
  (entity) => ({
    ...entity,
    position: [
      entity.position[0] + delta[0],
      entity.position[1] + delta[1],
      entity.position[2] + delta[2],
    ]
  })
```

### The pipeline pattern

```typescript
const processFrame = (universe: Universe, frame: XRFrame): Universe =>
  pipe(
    universe,
    (u) => processHandInput(u, frame),    // Input layer
    (u) => applyGestureEvents(u),         // Core layer
    (u) => updateGraphicsState(u),        // Graphics layer
  )
```

### The fold pattern (reducing over a collection)

```typescript
// Apply a list of events to produce a new state
const applyEvents = (state: NuclearState, events: AppEvent[]): NuclearState =>
  events.reduce(applyEvent, state)
```

### The lens pattern (immutable deep update)

```typescript
// Without lens:
const newUniverse: Universe = {
  ...universe,
  nuclearState: {
    ...universe.nuclearState,
    entities: new Map([
      ...universe.nuclearState.entities,
      [id, updatedEntity]
    ])
  }
}

// With lens (monocle-ts):
const entitiesLens = Lens.fromPath<Universe>()(['nuclearState', 'entities'])
const newUniverse = entitiesLens.modify(
  entities => new Map([...entities, [id, updatedEntity]])
)(universe)
```

### The event sourcing pattern (planned)

```typescript
type Event = AppEvent
type EventLog = readonly Event[]

// Rebuild any past state by replaying events from the beginning
const rebuildState = (log: EventLog): NuclearState =>
  log.reduce(applyEvent, initialNuclearState)
```

This is the foundation for multiplayer sync — broadcast events, not snapshots.
