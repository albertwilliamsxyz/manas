# ADR-008 — Immutable, Functional State Management

**Status:** Accepted  
**Date:** 2025  

---

## Context

The application's rendering loop runs at 72–120 Hz. Each frame reads the application state to decide what to draw. If state is mutated mid-frame (from an async callback, an event handler, or a co-routine), the rendered image may not correspond to any coherent state — a classic race condition even in a single-threaded JavaScript environment (e.g. microtask interleaving).

Additionally, features planned for the roadmap — **undo/redo**, **multiplayer sync**, **event sourcing** — all become trivial when state is immutable: you keep previous versions, replay events, or diff two states.

---

## Decision

All application state transitions produce a **new state object** — the original is never mutated.

---

## Pattern

```typescript
// ✗ Mutation — do not do this
universe.nuclearState.entities.set(id, updatedEntity)

// ✓ Immutable update — creates a new Universe
const newUniverse: Universe = {
  ...universe,
  nuclearState: {
    ...universe.nuclearState,
    entities: new Map([...universe.nuclearState.entities, [id, updatedEntity]])
  }
}
```

With **monocle-ts lenses** this pattern is ergonomic:

```typescript
import { Lens } from 'monocle-ts'

const entitiesLens = Lens.fromPath<Universe>()(['nuclearState', 'entities'])

const newUniverse = entitiesLens.modify(
  entities => new Map([...entities, [id, updatedEntity]])
)(universe)
```

---

## Tick model

Each application tick is a **pure function**:

```typescript
type Tick = (universe: Universe, frame: XRFrame) => Universe
```

No globals are mutated. The returned `Universe` becomes the input to the next tick. Side effects (WebGL calls, `console.log`) happen at the boundaries — the Display and Graphics layers — but they read from the immutable state; they do not write to it.

---

## Performance considerations

### Shallow copies are cheap

JavaScript spread (`{ ...obj }`) and `new Map([...map])` are O(n) in the number of fields / entries but they copy **references**, not deep values. For a `Universe` with tens or hundreds of entities this is negligible compared to GPU overhead.

### Shared references

Immutable data can be shared safely. The `Models` map (vertex data) is never mutated after load — all `Universe` versions share the same `Model` objects in memory. Only the part of the state that changes is re-allocated.

### When performance becomes a concern

If profiling shows state copying as a bottleneck:
1. Use **persistent data structures** (e.g. a hash-array mapped trie, as in Clojure's PersistentMap) for O(log n) updates.
2. Consider **monocle-ts** `Optional` / `Traversal` combinators which can batch multiple updates into a single pass.

---

## Undo/redo (planned)

Because each state is a value, undo/redo is a simple stack:

```typescript
type History = {
  past:    Universe[]
  present: Universe
  future:  Universe[]
}

const undo = (h: History): History => ({
  past:    h.past.slice(0, -1),
  present: h.past[h.past.length - 1],
  future:  [h.present, ...h.future]
})
```

No "undo manager" pattern needed — it falls out of immutability for free.

---

## Multiplayer sync (planned)

The `NuclearState` is the unit of synchronisation. Because it is immutable:
- **Event sourcing:** broadcast the event (e.g. `EntityMoved`) rather than the new state.
- **CRDT:** apply events in any order and arrive at the same state (idempotent, commutative operations).
- **Snapshot:** send the full `NuclearState` to a joining client — it starts from a known-good baseline.

---

## Consequences

- **Positive:** No race conditions — state is never partially updated.
- **Positive:** Undo/redo and time-travel debugging are trivial.
- **Positive:** Multiplayer sync is straightforward (event sourcing, CRDT).
- **Positive:** Pure tick function is testable without mocking.
- **Negative:** Slightly more verbose update syntax (mitigated by monocle-ts lenses).
- **Negative:** Garbage collector pressure increases (more short-lived objects) — acceptable at current scale; use persistent data structures if needed.
