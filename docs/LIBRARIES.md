# Libraries Reference

A deep-dive into every dependency declared in `package.json` and how it is used in this project.

---

## Runtime dependencies

### fp-ts `^2.16.11`

**What it is:** A library for typed functional programming in TypeScript. It brings algebraic structures (functors, monads, applicatives) from Haskell/Scala into TypeScript with full type safety.

**Homepage:** https://gcanti.github.io/fp-ts/

#### Modules used

##### `fp-ts/Option`

Represents a value that may or may not be present. Replaces `null` / `undefined` with an explicit algebraic type.

```typescript
import * as O from 'fp-ts/Option'

type Option<A> = None | Some<A>
// None = { _tag: 'None' }
// Some = { _tag: 'Some'; value: A }
```

| Function | Purpose |
|----------|---------|
| `O.some(a)` | Wrap a present value |
| `O.none` | Signal absence |
| `O.map(f)` | Apply `f` inside `Some`, pass `None` through |
| `O.chain(f)` | Sequence: `f` returns `Option<B>`, flattens |
| `O.match(onNone, onSome)` | Pattern match — forces handling both branches |
| `O.fromNullable(a)` | Convert a nullable value to `Option` |

**Used in this project:** `getApplicationCanvas()` returns `O.Option<HTMLCanvasElement>`.

---

##### `fp-ts/Either`

Represents a computation that may succeed (`Right`) or fail (`Left`). The error type is explicit in the signature.

```typescript
import * as E from 'fp-ts/Either'

type Either<E, A> = Left<E> | Right<A>
// Left  = { _tag: 'Left';  left:  E }
// Right = { _tag: 'Right'; right: A }
```

| Function | Purpose |
|----------|---------|
| `E.right(a)` | Success value |
| `E.left(e)` | Failure value |
| `E.map(f)` | Transform the `Right` value |
| `E.chain(f)` | Sequence fallible operations; short-circuits on `Left` |
| `E.match(onLeft, onRight)` | Pattern match |
| `E.mapLeft(f)` | Transform the error |

**Used in this project:** Every WebGL2 creation step (`createVertexShader`, `initializeVertexShader`, `createGraphicLibraryContext`, `initializeProgram`) returns `E.Either<Error, T>`.

---

##### `fp-ts/function`

```typescript
import { pipe, flow, identity } from 'fp-ts/function'
```

| Function | Description |
|----------|-------------|
| `pipe(a, f, g, h)` | Apply `f`, `g`, `h` left-to-right: `h(g(f(a)))` |
| `flow(f, g, h)` | Compose functions (no initial value): returns `x => h(g(f(x)))` |
| `identity` | `a => a` — the identity morphism |

**`pipe` is the primary composition primitive used throughout the project.** Every pipeline in `main.ts` uses it.

---

#### Why fp-ts over alternatives?

| Alternative | Reason not chosen |
|-------------|------------------|
| Native `try/catch` | Error type invisible in signature; untyped |
| `null` checks | Verbose; easy to forget; not composable |
| `neverthrow` | Smaller ecosystem; less alignment with CT |
| `effect` (Effect-TS) | Excellent but significantly heavier; planned for later exploration |

---

### monocle-ts `^2.3.13`

**What it is:** An optics library for TypeScript. Optics (lenses, prisms, optionals, traversals) are functional abstractions for reading and writing into deeply nested immutable data structures.

**Homepage:** https://gcanti.github.io/monocle-ts/

#### Core concept: Lens

A `Lens<S, A>` is a pair of functions:
- `get: S → A` — read a field
- `set: A → S → S` — write a field, producing a new `S`

```typescript
import { Lens } from 'monocle-ts'

type EntityDetails = { position: Vec3; rotation: Vec3; scale: Vec3 }

const positionLens = Lens.fromProp<EntityDetails>()('position')

positionLens.get(entity)              // Vec3
positionLens.set([0, 1, 0])(entity)  // EntityDetails (new object)
positionLens.modify(([x,y,z]) => [x, y+0.1, z])(entity)  // EntityDetails
```

#### Lens composition

```typescript
// Compose two lenses: Universe → NuclearState → entities map
const entitiesLens = Lens.fromPath<Universe>()(['nuclearState', 'entities'])
```

Composed lenses read/write deeply nested fields in a single expression, without destructuring and re-spreading at every level.

#### Other optics

| Optic | Use case |
|-------|---------|
| `Lens<S, A>` | Focus on a field that always exists |
| `Optional<S, A>` | Focus on a field that may not exist (like `Lens` for `Option`) |
| `Prism<S, A>` | Focus on one variant of a sum type |
| `Traversal<S, A>` | Focus on multiple fields at once (e.g. all entity positions) |

**Planned use in this project:** Updating deeply nested `Universe` state during event processing without manual spread chains.

---

### lodash `^4.17.23`

**What it is:** A battle-tested utility library for JavaScript — collections, objects, strings, math.

**Homepage:** https://lodash.com/

#### Relevant functions for this project

| Function | Use case |
|----------|---------|
| `_.cloneDeep(obj)` | Deep clone when a true copy is needed (rare in immutable style) |
| `_.merge(target, source)` | Deep merge two objects |
| `_.groupBy(collection, key)` | Group entities by model, layer, etc. |
| `_.keyBy(collection, key)` | Convert array to map by key |
| `_.pick(obj, keys)` | Subset of an object |
| `_.omit(obj, keys)` | Object without certain keys |
| `_.chunk(array, size)` | Split array into chunks |
| `_.range(start, end)` | Generate sequences |
| `_.throttle(fn, ms)` | Rate-limit event handlers |
| `_.debounce(fn, ms)` | Delay until input stops |

**Note:** Prefer fp-ts combinators for pipeline operations. Reach for lodash for operations not covered by fp-ts (deep clone, throttle, utility transforms).

**Tree-shaking:** Import individual functions to keep bundle size minimal:
```typescript
import cloneDeep from 'lodash/cloneDeep'   // not: import _ from 'lodash'
```

---

### uuid `^13.0.0`

**What it is:** Generates RFC-compliant Universally Unique Identifiers.

**Homepage:** https://github.com/uuidjs/uuid

#### API used

```typescript
import { v4 as uuidv4 } from 'uuid'

const entityId: EntityId = uuidv4()  // e.g. '110e8400-e29b-41d4-a716-446655440000'
```

#### Why UUID for entity IDs?

| Alternative | Problem |
|-------------|---------|
| `Date.now() + Math.random()` (old approach) | Collisions possible; not sortable; not standard |
| Sequential integers | Not safe for multiplayer (two clients both generate ID 1) |
| `crypto.randomUUID()` | Excellent alternative — browser-native, no dependency |
| UUID v4 | Random, collision-resistant, universally understood |

**Note:** `crypto.randomUUID()` is available in modern browsers and is a valid zero-dependency alternative. UUID v4 adds a small bundle cost but provides broader compatibility and a richer API (v1, v3, v5 if needed).

---

## Dev dependencies

### `@types/webxr` `^0.5.24`

**What it is:** TypeScript type declarations for the WebXR Device API. The WebXR API is not yet part of the TypeScript `dom` lib, so this package provides the types separately.

**Provides:** `XRSystem`, `XRSession`, `XRFrame`, `XRViewerPose`, `XRView`, `XRWebGLLayer`, `XRReferenceSpace`, `XRInputSource`, `XRHand`, `XRJointSpace`, `XRJointPose`, etc.

**Why it matters:** Without this package, every WebXR call would require `(navigator as any).xr` or similar casts, defeating the purpose of TypeScript.

**Important:** These types track the spec but may lag behind browser implementations. If a method appears in the browser but not in the types, a targeted `// @ts-ignore` or a local declaration merging is acceptable.

---

### `@vitejs/plugin-basic-ssl` `^2.1.4`

**What it is:** A Vite plugin that automatically generates a self-signed TLS certificate and configures the dev server to serve over HTTPS.

**Why it is needed:** WebXR requires a secure context. Testing on a physical headset (Meta Quest) on the local network requires HTTPS. This plugin eliminates the manual `openssl` step.

**Usage:**

```javascript
// vite.config.js
import basicSsl from '@vitejs/plugin-basic-ssl'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [basicSsl()],
  server: { https: true },
})
```

**Limitation:** The generated certificate is not trusted by browsers — users see a security warning. This is acceptable for local development. For any deployed environment, use a proper certificate (e.g. Let's Encrypt).

---

## Dependency decision summary

| Library | Decision | Reasoning |
|---------|----------|-----------|
| `fp-ts` | ✅ Core | CT-aligned, typed error handling, composition |
| `monocle-ts` | ✅ Core | Immutable deep updates via lenses |
| `lodash` | ✅ Utility | Battle-tested utilities not covered by fp-ts |
| `uuid` | ✅ Identifiers | Collision-resistant entity IDs for multiplayer |
| `@types/webxr` | ✅ Dev | TypeScript types for WebXR API |
| `@vitejs/plugin-basic-ssl` | ✅ Dev | HTTPS for WebXR local dev |
| `gl-matrix` | ❌ Not used | Matrix math done by hand (understanding first) |
| `three.js` | ❌ Not used | WebGL used directly (understanding first) |
| `rxjs` | ❌ Not yet | Event streams — possible future addition |
| `effect` | ❌ Not yet | Heavier FP runtime — planned exploration |
