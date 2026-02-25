# ADR-001 — TypeScript over plain JavaScript

**Status:** Accepted  
**Date:** 2025  

---

## Context

The first version of Manas was written in vanilla JavaScript (`src/main.old.js`). It worked, but as the project grew — more layers, more data structures, more mathematical invariants — the lack of type information made it increasingly hard to reason about correctness at a glance.

The project uses **Category Theory** as its architectural backbone. Category Theory is fundamentally a theory of *types and the functions between them*. A language with a strong static type system is a natural companion because the types in code become the objects of the category and the functions become the morphisms.

---

## Decision

Migrate to **TypeScript** (strict mode).

---

## Rationale

| Concern | TypeScript solution |
|---------|---------------------|
| Algebraic data types (product & sum) | `type`, `interface`, discriminated unions |
| Categorical morphisms | Function signatures `(A) => B` are self-documenting contracts |
| WebGL / WebXR type safety | `@types/webxr`, DOM lib — no more `any` for GPU objects |
| Refactoring confidence | The compiler rejects mismatched morphisms before runtime |
| Domain modeling | Custom type aliases (`type EntityId = string`) create a domain vocabulary |

### Strict mode (`"strict": true`)

Every value must be typed. `null` / `undefined` are not assignable without explicit `| null` or `Option`. This forces all failure paths to be handled, which aligns with the fp-ts philosophy of using `Option` and `Either` instead of exceptions.

---

## Consequences

- **Positive:** The type system documents the architecture. Reading `(universe: Universe) => Universe` immediately tells you this is a pure state transition.
- **Positive:** Compiler catches misuse of WebGL opaque handles (`WebGLBuffer`, `WebGLVertexArrayObject`, etc.) — they are distinct types, not interchangeable `number`s.
- **Negative:** Minor compilation step (handled by Vite's esbuild — zero config, instant).
- **Negative:** Some WebXR APIs require `@types/webxr` which is maintained separately from browser releases; occasional minor lag.

---

## Configuration (`tsconfig.json`)

```json
{
  "compilerOptions": {
    "lib": ["dom", "esnext"],
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "Node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

- `lib: ["dom", "esnext"]` — includes browser globals and modern JS APIs.
- `target: "ES2020"` — keeps async/await, `BigInt`, optional chaining native; Vite handles down-levelling for older targets if needed.
- `strict: true` — enables `noImplicitAny`, `strictNullChecks`, and all related flags.
