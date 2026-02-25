# ADR-002 — Functional Programming with fp-ts

**Status:** Accepted  
**Date:** 2025  

---

## Context

The application's architecture is modelled on Category Theory. In practice this means:
- Every computation is a **pure function** — same input always yields the same output.
- Failure is a **value**, not an exception.
- Composition is **explicit and type-safe**.

Plain TypeScript provides the type system but not the vocabulary. `fp-ts` provides the algebraic structures (functors, monads, applicatives) that turn abstract category theory into runnable TypeScript.

---

## Decision

Use **fp-ts** as the primary functional-programming library.

---

## Core concepts used in this project

### `Option<A>` — absence without `null`

```typescript
import * as O from 'fp-ts/Option'

// Instead of:                         // With Option:
const el = document.getElementById(…)  const el: O.Option<HTMLCanvasElement> =
if (!el) throw …                         el ? O.some(el) : O.none
```

`O.none` is a typed signal that the value is absent. `O.some(x)` wraps a present value. The compiler forces you to handle both cases before you can use the value.

**Used in:** `getApplicationCanvas()` — the canvas might not exist in the DOM.

---

### `Either<E, A>` — typed failure

```typescript
import * as E from 'fp-ts/Either'

// Left = failure (convention: Error)
// Right = success (convention: value)
const ctx: E.Either<Error, WebGL2RenderingContext> =
  gl ? E.right(gl) : E.left(new Error('WebGL2 not supported'))
```

`Either` is the categorical product of error and success paths. Unlike `try/catch`, the error type is part of the function signature — callers *know* a function can fail.

**Used in:**
- `createGraphicLibraryContext` — WebGL2 may not be available.
- `createVertexShader` / `createFragmentShader` — shader creation can fail.
- `initializeVertexShader` / `initializeFragmentShader` — compilation can fail.
- `initializeProgram` — linking can fail.

---

### `pipe` — left-to-right composition

```typescript
import { pipe } from 'fp-ts/function'

const vertexShader: WebGLShader = pipe(
  createVertexShader(gl),                                       // Either<Error, WebGLShader>
  E.chain(vs => initializeVertexShader(gl, vs)),               // Either<Error, WebGLShader>
  E.match(
    (err) => { throw err },                                     // Left branch
    (vs)  => vs                                                 // Right branch
  )
)
```

`pipe(value, f, g, h)` is equivalent to `h(g(f(value)))` but reads in the natural left-to-right order of data flow. It is the direct implementation of **morphism composition** in Category Theory: `h ∘ g ∘ f`.

---

### `E.chain` — monadic bind (`>>=`)

`E.chain` sequences operations that may fail: if the previous step produced a `Left` (error), the chain short-circuits and propagates the error without executing subsequent steps. This is the **monad** behaviour of `Either`.

---

### `E.match` / `O.match` — structural pattern matching

```typescript
O.match(
  () => { /* None branch */ },
  (value) => { /* Some branch */ }
)
```

Eliminates `if (!value)` noise. Both branches are required by the type system — you cannot forget to handle `None`.

---

## Why not use exceptions?

| Exceptions | fp-ts |
|-----------|-------|
| Invisible in type signatures | Error type in signature (`Either<Error, A>`) |
| Can be ignored silently | Compiler forces handling |
| Control flow is non-local (jumps) | Explicit pipeline with `chain` |
| Hard to compose | `chain`, `map`, `ap` compose naturally |

---

## Consequences

- **Positive:** Failure modes are first-class citizens visible in types.
- **Positive:** Pipeline code (`pipe`) reads as a data-flow diagram — aligns with the "discover the program" philosophy.
- **Positive:** `Option` / `Either` are standard algebraic structures — any developer fluent in FP immediately understands the intent.
- **Negative:** Learning curve for developers unfamiliar with FP / CT.
- **Negative:** Minor bundle size cost (~10 KB gzipped for the modules used).
