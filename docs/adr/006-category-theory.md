# ADR-006 — Category Theory as the Design Philosophy

**Status:** Accepted  
**Date:** 2025  

---

## Context

Most software is designed around objects that encapsulate both data and behaviour (OOP) or around isolated procedures (imperative). Neither makes the compositional structure of the system explicit in the code.

The author's core insight is: **the program is not built — it is discovered**. It exists as a computable process. The task is to find the right representation — the types and the functions between them — such that composing them produces the desired experience. Category Theory provides the mathematical vocabulary for that search.

---

## Decision

Use **Category Theory** as the primary design lens. Every architectural decision is justified in CT terms.

---

## Key CT mappings

### Objects = Types

Every meaningful domain concept is a named type:

```typescript
type EntityId  = string           // not just 'string' — an entity identifier
type ModelId   = string
type Vec3      = [number, number, number]
type GestureKind = 'idle' | 'pinch' | 'grab'
```

Types are the **objects** of the category. When you see `EntityId → EntityDetails`, you are reading a morphism in the category of domain types.

---

### Morphisms = Pure Functions

A morphism `f: A → B` is a pure function with no side effects. Side effects are pushed to the edges (Display layer, Input layer).

```typescript
// Morphism: NuclearState × Event → NuclearState
const applyEvent = (state: NuclearState, event: AppEvent): NuclearState => { … }

// Morphism: Vec3 × Vec3 × Vec3 → Mat4
const composeModelMatrix = (position: Vec3, rotation: Vec3, scale: Vec3): Mat4 => { … }
```

---

### Composition = `pipe`

```typescript
import { pipe } from 'fp-ts/function'

// f ∘ g ∘ h  written left-to-right:
const result = pipe(initialValue, f, g, h)
```

`pipe` is the **categorical composition operator**. The type checker verifies that the output type of each step matches the input type of the next — enforcing the law that morphisms must compose.

---

### Functors = `map` on containers

A functor is a structure-preserving map between categories. In practice:

```typescript
// Option is a functor: maps a function A → B over Option<A> to get Option<B>
const length: O.Option<number> = pipe(
  getApplicationCanvas(),          // Option<HTMLCanvasElement>
  O.map(canvas => canvas.width)    // Option<number>
)

// Array is a functor
const positions: Vec3[] = entities.map(e => e.position)
```

---

### Monad = `chain` (sequencing with failure)

A monad lets you sequence operations where each step may fail (or produce context):

```typescript
// Either monad: short-circuits on Left (failure)
const program: E.Either<Error, WebGLProgram> = pipe(
  createVertexShader(gl),                                  // Either<Error, WebGLShader>
  E.chain(vs => initializeVertexShader(gl, vs)),          // Either<Error, WebGLShader>
  E.chain(vs => E.map((fs: WebGLShader) =>
    initializeProgram(gl, createProgram(gl), vs, fs)
  )(initializeFragmentShader(gl, createFragmentShader(gl) as any)))
)
```

---

### Sum types = coproducts (discriminated unions)

```typescript
type AppEvent =
  | { tag: 'EntityAdded';   entityId: EntityId; modelId: ModelId }
  | { tag: 'EntityMoved';   entityId: EntityId; delta: Vec3 }
  | { tag: 'PinchStarted';  hand: 'left' | 'right'; position: Vec3 }
  | { tag: 'PinchEnded';    hand: 'left' | 'right' }
```

The `tag` field acts as the discriminant (the categorical injector). Pattern matching on `tag` exhaustively handles all variants — the compiler warns if a new variant is added but a match arm is missing.

---

### The Universe as the terminal object

In a category there is often a **terminal object** — a type `T` such that for every other type `A`, there is exactly one morphism `A → T`. The **Universe** plays this role in the application: every system transformation is ultimately a morphism into (or within) `Universe`.

```typescript
// Every tick is a morphism: Universe → Universe
type Tick = (universe: Universe) => Universe

// Built by composing layer ticks:
const tick: Tick = pipe(
  processInput,      // Universe → Universe (updates NuclearState via events)
  renderGraphics,    // Universe → Universe (GPU side-effects)
  displayFrame       // Universe → Universe (schedules next frame)
)
```

---

### Lenses (monocle-ts) = morphisms into sub-objects

A **lens** is a pair of morphisms: `get: S → A` and `set: A → S → S`. It focuses on a piece of a larger structure without copying everything manually:

```typescript
import { Lens } from 'monocle-ts'

const positionLens: Lens<EntityDetails, Vec3> = Lens.fromProp<EntityDetails>()('position')

// Read
const pos: Vec3 = positionLens.get(entityDetails)

// Write (returns new EntityDetails, original unchanged)
const moved: EntityDetails = positionLens.set([1, 2, 3])(entityDetails)
```

Lenses compose — zoom into deeply nested fields with a single composed lens.

---

## "Discovering" the program

The philosophical stance is: the program *already exists* as a mathematical object. Development is the act of **discovering** the right decomposition of that object into computable primitives. This means:

1. Start by naming the objects (types) correctly.
2. Discover the natural morphisms (functions) between them.
3. Compose morphisms until the desired behaviour emerges.
4. Never force a design — if composition feels unnatural, the types are probably wrong.

This is why type aliases like `type EntityId = string` matter: they are not cosmetic — they carve reality at its joints.

---

## Consequences

- **Positive:** The codebase is self-documenting in mathematical terms.
- **Positive:** Invariants can be expressed as types (e.g. `GestureKind` guarantees only valid states exist).
- **Positive:** Composition is mechanically checked by the compiler.
- **Positive:** The mental model scales: adding a new layer or feature is adding a new category and functors into the existing system.
- **Negative:** Requires familiarity with CT vocabulary to contribute.
