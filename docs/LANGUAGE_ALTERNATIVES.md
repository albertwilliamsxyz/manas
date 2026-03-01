# PureScript-Like Language Alternatives for Manas

## Purpose

This document analyzes functional programming languages that compile to JavaScript and could replace TypeScript as the primary language for this project. The evaluation is grounded in the specific requirements of Manas: category theory-based architecture, WebGL2/WebXR rendering, algebraic data types, immutable state management, and functional composition.

---

## Current Stack Analysis

The project currently uses TypeScript with functional programming libraries to approximate a pure FP experience:

| Component | Current Tool | Role |
|---|---|---|
| Language | TypeScript | Static typing, ES2020 target |
| FP Core | `fp-ts` | `Either`, `Option`, `pipe`, monadic composition |
| Optics | `monocle-ts` | Lenses for immutable data updates |
| Bundler | Vite | Fast dev server with HTTPS/SSL |
| Graphics | WebGL2 (native) | 3D rendering, shaders |
| Immersive | WebXR (native) | AR/VR sessions, hand tracking |

**Patterns already in use:**
- `Either<Error, T>` for error handling without exceptions
- `Option<T>` for nullable values
- `pipe()` for left-to-right function composition
- `E.chain()` for monadic sequencing
- `E.match()` / `O.match()` for pattern matching
- Architecture design in Haskell pseudocode (see `docs/architecture/DESIGN.md`)
- Category theory concepts: functors, monads, composition, coproducts (sum types)

**Friction points with TypeScript + fp-ts:**
- Type classes are simulated, not native (no `Functor`, `Monad` instances)
- Pattern matching is emulated via `.match()` callbacks, not exhaustive by default
- Purity is a convention, not enforced by the compiler
- Higher-kinded types require workaround encoding (HKT simulation)
- No native algebraic data types (discriminated unions are the closest approximation)
- Mutable state is always accessible, immutability is opt-in

---

## Evaluation Criteria

Each language is evaluated on criteria specific to this project:

1. **FP Purity** — Does the compiler enforce purity? Are effects tracked in the type system?
2. **Type System Power** — ADTs, type classes, higher-kinded types, type inference
3. **Category Theory Support** — Native `Functor`, `Monad`, `Applicative`, lenses, optics
4. **WebGL2/WebXR Interop** — Can it call browser APIs directly? FFI ergonomics
5. **Build Tooling** — Integration with Vite or similar bundlers, dev experience
6. **Ecosystem Maturity** — Library availability, community size, documentation
7. **Bundle Size & Performance** — Runtime overhead, output JS quality
8. **Migration Path** — How much of the current codebase can be incrementally ported

---

## Language Analysis

### 1. PureScript ⭐ (Recommended)

**Overview:** A strongly-typed, purely functional language inspired by Haskell that compiles to readable JavaScript. Designed specifically for the JS ecosystem with a focus on correctness and expressiveness.

| Criterion | Rating | Notes |
|---|---|---|
| FP Purity | ★★★★★ | Effects tracked via `Effect` and `Aff` monads. Purity enforced by compiler |
| Type System | ★★★★★ | Hindley-Milner inference, ADTs, type classes, higher-kinded types, row polymorphism, kind system |
| Category Theory | ★★★★★ | Native `Functor`, `Monad`, `Applicative`, `Semigroupoid`, `Category`. Optics via `profunctor-lenses` |
| WebGL2/WebXR | ★★★★☆ | `purescript-webgl2-raw` for WebGL2. WebXR requires custom FFI bindings |
| Build Tooling | ★★★☆☆ | Uses `spago` (not Vite-native), but output JS can be bundled with any JS bundler |
| Ecosystem | ★★★☆☆ | Smaller than TS but mature core libraries. Package registry: Pursuit |
| Bundle Size | ★★★★☆ | Small runtime, readable JS output, dead code elimination |
| Migration Path | ★★★★★ | Incremental: PureScript modules can coexist with JS/TS via FFI |

**Why PureScript is the best fit for this project:**

- The architecture in `docs/architecture/DESIGN.md` is already written in Haskell, and PureScript syntax is nearly identical to Haskell. The categorical implementation plan translates almost directly:

```haskell
-- DESIGN.md (current Haskell pseudocode)
data Model = Model {
  modelId    :: String,
  vertices   :: [Vertex],
  connections :: [Connection],
  geometry   :: Geometry
}

-- PureScript (actual executable code, nearly identical)
type Model =
  { modelId    :: String
  , vertices   :: Array Vertex
  , connections :: Array Connection
  , geometry   :: Geometry
  }
```

- The `fp-ts` patterns used in `src/main.ts` map directly to PureScript's standard library:

```
-- TypeScript + fp-ts              →  PureScript
import * as E from 'fp-ts/Either'  →  import Data.Either (Either(..))
import * as O from 'fp-ts/Option'  →  import Data.Maybe (Maybe(..))
import { pipe } from 'fp-ts/...'   →  (# operator or built-in)
E.right(value)                     →  Right value
E.left(error)                      →  Left error
E.chain(fn)                        →  >>= (bind) or =<< 
E.match(onLeft, onRight)           →  case ... of / either
O.some(value)                      →  Just value
O.none                             →  Nothing
```

- PureScript has `purescript-webgl2-raw` which provides complete WebGL2 bindings, matching the low-level WebGL2 usage in the current codebase.
- Row polymorphism enables extensible records, which fits the layered architecture (nuclear state, graphics state, gesture state) described in `docs/architecture/NOTES.md`.
- The `Effect` monad tracks side effects explicitly, which aligns with the project's goal of separating pure computation from rendering.

**Considerations:**
- WebXR bindings would need to be written via FFI (straightforward, similar to how `@types/webxr` works).
- Build pipeline needs `spago` alongside Vite (the compiled JS output integrates with any bundler).
- Steeper learning curve than TypeScript for new contributors unfamiliar with Haskell-like syntax.

---

### 2. Elm

**Overview:** A pure functional language for reliable web applications, compiling to JavaScript. Known for "no runtime exceptions" and excellent error messages.

| Criterion | Rating | Notes |
|---|---|---|
| FP Purity | ★★★★★ | Purely functional, no escape hatches |
| Type System | ★★★☆☆ | ADTs and pattern matching, but **no type classes** and no higher-kinded types |
| Category Theory | ★★☆☆☆ | No type classes means no `Functor`/`Monad` abstractions. Manual implementations only |
| WebGL2/WebXR | ★★☆☆☆ | WebGL support exists via `elm-explorations/webgl`. WebXR only via JS ports (restricted interop) |
| Build Tooling | ★★★★☆ | Self-contained compiler, good dev experience |
| Ecosystem | ★★★☆☆ | Strong for SPAs, but limited for graphics-heavy applications |
| Bundle Size | ★★★★★ | Very small output, excellent dead code elimination |
| Migration Path | ★★☆☆☆ | Elm's restrictive interop (ports-only) makes incremental migration harder |

**Why Elm is not ideal for this project:**
- The absence of type classes makes it impossible to express the category theory abstractions (`Functor`, `Monad`, `Applicative`) that are central to the architecture. The Haskell pseudocode in `DESIGN.md` would lose its categorical structure.
- The ports-based JS interop is deliberately restrictive, which conflicts with the direct WebGL2 buffer manipulation and WebXR session management the project requires.
- Elm is optimized for form-based SPAs, not real-time 3D rendering with hand tracking.

---

### 3. ReScript (formerly BuckleScript/ReasonML)

**Overview:** An OCaml-inspired language with excellent JavaScript interop and extremely fast compilation. Focuses on pragmatism and readability.

| Criterion | Rating | Notes |
|---|---|---|
| FP Purity | ★★★☆☆ | Functional by default, but mutable state is accessible. Purity not enforced |
| Type System | ★★★★☆ | Strong nominal types, ADTs, pattern matching, type inference. No higher-kinded types |
| Category Theory | ★★☆☆☆ | No type classes (module functors exist but are different). Category theory abstractions need manual encoding |
| WebGL2/WebXR | ★★★★★ | Excellent JS FFI, seamless interop with any browser API |
| Build Tooling | ★★★★★ | Blazing fast compilation, first-class JS integration |
| Ecosystem | ★★★★☆ | Strong React ecosystem, growing general-purpose libraries |
| Bundle Size | ★★★★★ | Produces clean, human-readable JS output |
| Migration Path | ★★★★☆ | Excellent JS interop makes incremental migration feasible |

**Trade-offs for this project:**
- ReScript excels at JS interop and compilation speed, making it practical for WebGL2/WebXR work.
- However, the lack of type classes and higher-kinded types means the category theory architecture cannot be expressed directly. The `Functor`/`Monad` hierarchy and the categorical design in `DESIGN.md` would need to be restructured.
- ReScript is more pragmatic than purely functional — it allows mutable state and doesn't track effects in the type system.
- Good choice if the priority shifts from category theory purity to development velocity and JS ecosystem integration.

---

### 4. F# via Fable

**Overview:** F# is a mature ML-family language from the .NET ecosystem. Fable compiles F# to JavaScript, enabling full-stack development.

| Criterion | Rating | Notes |
|---|---|---|
| FP Purity | ★★★☆☆ | Functional-first but supports OOP and imperative code |
| Type System | ★★★★☆ | Strong ML type system, ADTs (discriminated unions), computation expressions |
| Category Theory | ★★★☆☆ | No type classes. Computation expressions provide monadic syntax. Libraries like FSharpPlus add categorical abstractions |
| WebGL2/WebXR | ★★★★☆ | Fable provides good JS interop. Browser APIs accessible via bindings |
| Build Tooling | ★★★☆☆ | Requires .NET SDK + Fable toolchain. More complex than Vite-only setups |
| Ecosystem | ★★★★☆ | Large .NET ecosystem, growing Fable/JS community |
| Bundle Size | ★★★☆☆ | Reasonable but heavier than PureScript or ReScript |
| Migration Path | ★★★☆☆ | Requires .NET toolchain setup, different ecosystem |

**Trade-offs for this project:**
- F# has computation expressions that provide monadic `do`-notation, partially compensating for the lack of type classes.
- The .NET toolchain dependency adds complexity without clear benefit for a browser-only VR/AR application.
- Better suited for full-stack scenarios where backend and frontend share code in .NET.

---

### 5. Haskell via GHCJS

**Overview:** GHCJS compiles Haskell to JavaScript, bringing the full power of GHC's type system to the browser.

| Criterion | Rating | Notes |
|---|---|---|
| FP Purity | ★★★★★ | Full Haskell purity, IO monad for effects |
| Type System | ★★★★★ | GHC's type system: type classes, GADTs, type families, dependent types (partial) |
| Category Theory | ★★★★★ | Full Haskell ecosystem: `lens`, `mtl`, `category`, `profunctors` |
| WebGL2/WebXR | ★★★☆☆ | GHCJS FFI exists but is less ergonomic than PureScript's |
| Build Tooling | ★★☆☆☆ | Heavy toolchain, long compile times, complex setup |
| Ecosystem | ★★★★★ | Entire Hackage ecosystem (when packages compile to JS) |
| Bundle Size | ★☆☆☆☆ | Large output bundles, significant runtime overhead |
| Migration Path | ★★☆☆☆ | Heavy toolchain, poor bundle size for browser deployment |

**Trade-offs for this project:**
- GHCJS provides the most powerful type system of all options and the `DESIGN.md` Haskell code would work without modification.
- However, large bundle sizes and compile times make it impractical for a real-time VR/AR application where performance matters.
- PureScript provides nearly the same type system power with dramatically better JS integration and bundle sizes.

---

### 6. Gleam

**Overview:** A modern functional language targeting the BEAM (Erlang) VM and JavaScript. Emphasizes simplicity, friendly errors, and practical FP.

| Criterion | Rating | Notes |
|---|---|---|
| FP Purity | ★★★★☆ | Immutable by default, functional core, but not as strict as PureScript |
| Type System | ★★★☆☆ | ADTs, pattern matching, exhaustiveness checking. **No type classes**, no higher-kinded types |
| Category Theory | ★★☆☆☆ | No type classes means categorical abstractions must be manual |
| WebGL2/WebXR | ★★★☆☆ | Compiles to JS, but browser API bindings are minimal. Requires FFI glue code |
| Build Tooling | ★★★★☆ | Excellent tooling, fast compilation |
| Ecosystem | ★★☆☆☆ | Growing rapidly but still young, especially for browser/graphics work |
| Bundle Size | ★★★★☆ | Produces clean ES module output |
| Migration Path | ★★★☆☆ | JS interop possible but ecosystem is still developing |

**Trade-offs for this project:**
- Gleam is a rising language with excellent developer experience and clean syntax.
- However, the lack of type classes and the immature browser/graphics ecosystem make it a poor fit for category theory-heavy WebGL2 applications.
- Better suited for backend services on BEAM where its Erlang interop shines.

---

### 7. Idris 2

**Overview:** A dependently typed functional programming language with a JavaScript backend. Enables encoding invariants directly in types.

| Criterion | Rating | Notes |
|---|---|---|
| FP Purity | ★★★★★ | Pure, with tracked effects via quantitative type theory |
| Type System | ★★★★★+ | Dependent types: types can depend on values. Most powerful type system of all options |
| Category Theory | ★★★★★ | Type classes, dependent types enable proofs and verified abstractions |
| WebGL2/WebXR | ★★☆☆☆ | JavaScript backend exists but browser bindings are minimal |
| Build Tooling | ★★☆☆☆ | Niche toolchain, limited editor support compared to mainstream |
| Ecosystem | ★☆☆☆☆ | Very small ecosystem, primarily academic/research |
| Bundle Size | ★★☆☆☆ | JS output can be verbose and unoptimized |
| Migration Path | ★☆☆☆☆ | Steep learning curve, minimal ecosystem for web development |

**Trade-offs for this project:**
- Idris has the most powerful type system of all options, with dependent types allowing compile-time verification of vector dimensions, matrix compatibility, etc.
- However, the ecosystem is too immature for production browser applications. WebGL2 and WebXR bindings would need to be written from scratch.
- Interesting as a future exploration once the ecosystem matures, but not practical as a primary language today.

---

## Comparison Matrix

| | PureScript | Elm | ReScript | F# Fable | GHCJS | Gleam | Idris 2 |
|---|---|---|---|---|---|---|---|
| **FP Purity** | ★★★★★ | ★★★★★ | ★★★☆☆ | ★★★☆☆ | ★★★★★ | ★★★★☆ | ★★★★★ |
| **Type Classes** | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| **Higher-Kinded Types** | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| **ADTs** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Pattern Matching** | ✅ exhaustive | ✅ exhaustive | ✅ exhaustive | ✅ exhaustive | ✅ exhaustive | ✅ exhaustive | ✅ exhaustive |
| **Category Theory** | ★★★★★ | ★★☆☆☆ | ★★☆☆☆ | ★★★☆☆ | ★★★★★ | ★★☆☆☆ | ★★★★★ |
| **WebGL2 Bindings** | ✅ community | ✅ limited | ✅ via FFI | ✅ via FFI | ✅ via FFI | ⚠️ manual | ⚠️ manual |
| **WebXR Bindings** | ⚠️ custom FFI | ❌ ports only | ✅ via FFI | ✅ via FFI | ⚠️ via FFI | ⚠️ manual | ⚠️ manual |
| **JS FFI Quality** | ★★★★☆ | ★★☆☆☆ | ★★★★★ | ★★★★☆ | ★★★☆☆ | ★★★☆☆ | ★★★☆☆ |
| **Bundle Size** | Small | Very small | Very small | Medium | Large | Small | Medium |
| **Compile Speed** | Medium | Fast | Very fast | Medium | Slow | Fast | Slow |
| **Haskell Similarity** | ★★★★★ | ★★★☆☆ | ★★☆☆☆ | ★★★☆☆ | ★★★★★ | ★★☆☆☆ | ★★★★★ |
| **Learning Resources** | Good | Excellent | Good | Good | Excellent | Growing | Limited |

---

## Recommendation

### Primary: PureScript

PureScript is the strongest match for this project because:

1. **Direct alignment with the architecture.** The categorical implementation plan in `DESIGN.md` is written in Haskell syntax. PureScript shares this syntax and semantics, meaning the design documents become executable code with minimal changes.

2. **Native category theory support.** Type classes (`Functor`, `Monad`, `Applicative`, `Semigroupoid`, `Category`) are first-class citizens, not library simulations. The `fp-ts` and `monocle-ts` patterns translate to standard PureScript with no additional libraries.

3. **Effect tracking.** The `Effect` monad makes side effects (WebGL calls, DOM manipulation, XR sessions) explicit in the type system, enforcing the separation between pure computation and rendering that the architecture describes.

4. **WebGL2 support.** The `purescript-webgl2-raw` package provides comprehensive WebGL2 bindings matching the low-level API usage in the current codebase.

5. **Row polymorphism.** Extensible records enable the layered state architecture (Universe containing nuclear state, graphics state, gesture state) without the boilerplate of nominal types.

6. **Readable JS output.** PureScript compiles to clean, readable JavaScript, enabling debugging and performance profiling in browser dev tools.

7. **Incremental migration.** PureScript modules can coexist with existing TypeScript/JavaScript via FFI, allowing a gradual transition rather than a full rewrite.

### Secondary: ReScript

If maximum JS interop and compilation speed are prioritized over category theory purity, ReScript is a strong practical alternative. It would require restructuring the categorical architecture but offers the fastest development feedback loop and the most seamless integration with the existing JS ecosystem.

---

## Migration Path (PureScript)

### Phase 1: Setup & Coexistence
- Install PureScript toolchain (`spago`, `purs`)
- Configure output to integrate with existing Vite bundler
- Write FFI bindings for WebXR types (equivalent to current `@types/webxr`)

### Phase 2: Core Types
- Port the type definitions from `DESIGN.md` to actual PureScript modules
- Define `Universe`, `Entity`, `Model`, `Geometry` as PureScript types
- Implement the gesture FSM as a sum type with transitions

### Phase 3: Pure Logic
- Port pure functions (shader compilation, matrix operations, gesture detection)
- Implement the tick function as a pure state transformation
- Define the layer composition pipeline (nuclear → graphics → input → display)

### Phase 4: Effect Layer
- Wrap WebGL2 operations in `Effect` monad
- Wrap WebXR session management in `Aff` (async effects)
- Connect pure logic to effectful rendering via monadic composition

### Phase 5: Full Transition
- Remove `fp-ts` and `monocle-ts` dependencies
- Replace TypeScript entry point with PureScript
- Maintain JS FFI layer for WebXR hand tracking API

---

## Code Translation Examples

### Error Handling

**TypeScript + fp-ts (current):**
```typescript
const createVertexShader: (gl: WebGL2RenderingContext) => E.Either<Error, WebGLShader> = (
  gl: WebGL2RenderingContext
) => {
  const vertexShader: WebGLShader | null = gl.createShader(gl.VERTEX_SHADER)
  return vertexShader ? E.right(vertexShader) : E.left(new Error('Unable to create vertex shader'))
}
```

**PureScript (target):**
```purescript
createVertexShader :: WebGL2RenderingContext -> Effect (Either Error WebGLShader)
createVertexShader gl = do
  shader <- GL.createShader gl VertexShader
  pure $ maybe (Left (error "Unable to create vertex shader")) Right shader
```

### Function Composition

**TypeScript + fp-ts (current):**
```typescript
const vertexShader: WebGLShader = pipe(
  createVertexShader(gl),
  E.chain((vertexShader: WebGLShader) => initializeVertexShader(gl, vertexShader)),
  E.match(
    (error: Error) => { throw error },
    (vertexShader: WebGLShader) => vertexShader
  )
)
```

**PureScript (target):**
```purescript
vertexShader <- do
  shader <- createVertexShader gl >>= initializeVertexShader gl
  case shader of
    Left err -> throwError err
    Right vs -> pure vs
```

### Algebraic Data Types

**TypeScript (current, simulated):**
```typescript
// Discriminated union with manual type guards
type Geometry = 
  | { kind: 'polygon'; sides: number }
  | { kind: 'mesh'; faces: number }
  | { kind: 'custom'; description: string }
```

**PureScript (target, native ADTs):**
```purescript
data Geometry
  = Polygon Int
  | Mesh Int
  | Custom String

-- Exhaustive pattern matching enforced by compiler
describeGeometry :: Geometry -> String
describeGeometry = case _ of
  Polygon n -> "Polygon with " <> show n <> " sides"
  Mesh n    -> "Mesh with " <> show n <> " faces"
  Custom s  -> "Custom: " <> s
```

---

## Resources

- [PureScript official site](https://www.purescript.org/)
- [PureScript by Example (book)](https://book.purescript.org/)
- [Pursuit (package registry)](https://pursuit.purescript.org/)
- [purescript-webgl2-raw](https://github.com/chrismshelton/purescript-webgl2-raw)
- [Spago (build tool)](https://github.com/purescript/spago)
- [PureScript Halogen (UI framework)](https://github.com/purescript-halogen/purescript-halogen)
- [ReScript official site](https://rescript-lang.org/)
- [Elm official site](https://elm-lang.org/)
- [Gleam official site](https://gleam.run/)
- [Idris 2 JS backend](https://idris2.readthedocs.io/en/latest/backends/javascript.html)
- [F# Fable](https://fable.io/)
