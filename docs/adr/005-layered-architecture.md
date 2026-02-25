# ADR-005 — Layered Architecture

**Status:** Accepted  
**Date:** 2025  

---

## Context

As the project grows, the single-file approach of `main.old.js` becomes hard to reason about. Concerns intermingle: DOM queries, WebGL setup, XR session management, hand pose processing, and rendering are all woven together. Adding multiplayer, gesture recognition, or a scene graph to a monolithic file risks exponential coupling.

The project's Category Theory foundation provides the right tool: **layers are categories**, and the interfaces between them are **functors** — structure-preserving maps that translate one domain's types into another's.

---

## Decision

Organise the application into five conceptual layers, each with a clear responsibility boundary:

```
0. Navigator   — DOM / browser globals
1. Core        — domain logic, state, policies
2. Graphics    — WebGL2, GPU objects
3. Input       — WebXR hand tracking, gesture FSM
4. Display     — XR frame loop, per-eye rendering
```

---

## Layer contracts

### 0 — Navigator Layer

**Input:** Browser environment  
**Output:** `Option<HTMLCanvasElement>`

```typescript
const getApplicationCanvas = (): O.Option<HTMLCanvasElement> => { … }
```

Isolates `document.getElementById` so the rest of the code never touches the DOM directly. Returns `Option` — the canvas may not exist.

---

### 1 — Core (Nuclear) Layer

**Input:** Events from Input Layer  
**Output:** Updated `NuclearState`

Responsibilities:
- Maintains the authoritative source of truth for all scene entities.
- Applies events (gesture recognitions, model loads, entity mutations) as pure state transitions.
- Contains the Gesture FSM.
- No knowledge of WebGL, WebXR, or the DOM.

Pure function signature per tick:
```typescript
type CoreTick = (state: NuclearState, events: Event[]) => NuclearState
```

---

### 2 — Graphics Layer

**Input:** `NuclearState`, `Models`  
**Output:** GPU side-effects (VAO binds, uniform updates, draw calls)

Responsibilities:
- Creates and manages WebGL objects (shaders, program, VAOs, buffers).
- Maps each `EntityId` → a `{ vao, vertexCount }` record.
- Reads entity transform data from `NuclearState` to set `u_model` uniform before drawing.
- The only layer allowed to call WebGL APIs.

Key function:
```typescript
type DrawEntity = (gl: WebGL2RenderingContext, entity: EntityDetails, graphicData: EntityGraphicData) => void
```

---

### 3 — Input Layer

**Input:** `XRSession.inputSources` per frame  
**Output:** Hand vertex buffers, gesture events

Responsibilities:
- Reads 25 joint poses per hand from the WebXR frame.
- Fills `Float32Array` hand buffers for rendering.
- Computes gesture metrics (finger-tip distances, velocities).
- Emits typed events that the Core layer consumes.

Gesture detection (current — pinch):
```typescript
const distance = Math.sqrt(
  (indexTip[0] - thumbTip[0]) ** 2 +
  (indexTip[1] - thumbTip[1]) ** 2 +
  (indexTip[2] - thumbTip[2]) ** 2
)
if (distance < 0.02) { /* emit PinchEvent */ }
```

---

### 4 — Display Layer

**Input:** `XRFrame`, current `Universe`  
**Output:** GPU side-effects (framebuffer bind, viewport, draw scheduling)

Responsibilities:
- Binds the XR framebuffer.
- Iterates over `XRView` array (one per eye).
- Sets per-eye `u_projection` and `u_view` uniforms.
- Delegates draw calls to the Graphics layer.
- Schedules the next animation frame.

---

## Why this layering?

### Separation of concerns

Each layer can evolve independently:
- Want to try a different gesture recognition algorithm? Change only the Input layer.
- Add a Vulkan backend in the future? Replace only the Graphics layer.
- Add multiplayer? The Core layer is already isolated — just sync `NuclearState`.

### Testability

The Core layer has no side-effects. It is a pure function of state + events. It can be tested in Node.js without a browser, WebGL context, or XR device.

### Mirrors the data-flow

The layering matches the actual flow of information: hardware → input → domain → graphics → display. Reading the code top-to-bottom reveals the pipeline in the same order data flows through it.

---

## Consequences

- **Positive:** Clear ownership boundaries — easy to locate where a bug or feature lives.
- **Positive:** Core layer is portable (testable outside browser, syncable for multiplayer).
- **Positive:** Each layer's API can be typed precisely.
- **Negative:** More initial ceremony than a flat script (but pays off quickly as features grow).
