# Type Theory for TypeScript: A Conceptual Guide

## Vision and Purpose

This document explores type theory as it applies to TypeScript and this project's architecture. It builds a conceptual framework for understanding how types model the domain, how algebraic data types compose into powerful abstractions, and how category theory connects to the TypeScript type system. The goal is to give you the vocabulary and tools to think in types — discovering the program rather than just writing it.

---

## Visión y Propósito

Este documento explora la teoría de tipos aplicada a TypeScript y a la arquitectura de este proyecto. Construye un marco conceptual para entender cómo los tipos modelan el dominio, cómo los tipos de datos algebraicos se componen en abstracciones poderosas, y cómo la teoría de categorías se conecta con el sistema de tipos de TypeScript. El objetivo es darte el vocabulario y las herramientas para pensar en tipos: descubrir el programa en lugar de solo escribirlo.

---

## Fundamental Root: What is a Type?

A **type** is a set of values together with the operations that can be performed on them. Types constrain what a program can express and therefore what errors it can make.

- `number` is the set of all IEEE-754 floating-point values.
- `string` is the set of all Unicode character sequences.
- `boolean` is the two-element set `{ true, false }`.
- A custom type such as `EntityId` is a subset you define to give meaning to a raw primitive.

### Types as Sets

| Type expression        | Set semantics                          |
|------------------------|----------------------------------------|
| `never`                | Empty set — no value inhabits it       |
| `undefined`            | Singleton set `{ undefined }`          |
| `boolean`              | Two-element set `{ true, false }`      |
| `string`               | Infinite set of all strings            |
| `A \| B`               | Union — values from A **or** B         |
| `A & B`                | Intersection — values in A **and** B  |
| `[A, B]` (tuple)       | Cartesian product A × B                |

### Type Aliases — Your Own Vocabulary

Declaring a type alias creates a named abstraction over any type expression:

```typescript
type Scalar = number
type EntityId = string
type Timestamp = number
```

This is not just cosmetic: it encodes *intent*. A function that accepts `EntityId` documents that it expects an entity identifier, not an arbitrary string. This is the first step toward a domain-specific type language.

#### Exercises
1. Declare a type alias `Milliseconds` for `number`. Why is this better than using `number` directly?
2. What set of values does the type `never` represent? Give a real use case.
3. Express the Cartesian product of `string` and `number` as a TypeScript tuple type.

---

## Product Types

A **product type** combines multiple types into a single compound value. Every member must be present simultaneously — hence "product" (it is the Cartesian product of the component sets).

### Tuples

```typescript
type Vec2 = [number, number]
type Vec3 = [number, number, number]
type Vec4 = [number, number, number, number]

type Connection = [number, number]   // indices of two vertices
```

A `Vec3` has exactly three numbers. The size of the type is `|number| × |number| × |number|`.

### Records (Object Types)

```typescript
type Model = {
  readonly id: string
  readonly vertices: ReadonlyArray<Vec3>
  readonly connections: ReadonlyArray<Connection>
}

type Entity = {
  readonly id: EntityId
  readonly modelId: string
  readonly position: Vec3
  readonly rotation: Vec3
  readonly scale: Vec3
}
```

Records are the most common product types in TypeScript. Every field must be supplied; the value lives at the intersection of all field types.

### `readonly` for Immutability

Marking fields `readonly` makes the compiler reject mutation, matching the functional, immutable-state architecture of the project:

```typescript
type Universe = {
  readonly entities: ReadonlyArray<Entity>
  readonly models: Readonly<Record<string, Model>>
}
```

#### Exercises
1. Define a product type `Transform` with `position`, `rotation`, and `scale`, each of type `Vec3`.
2. Why does a record with N fields represent the Cartesian product of N types?
3. Add `readonly` to every field of `Entity` and explain the compile-time guarantee this provides.

---

## Sum Types (Union Types)

A **sum type** (also called a tagged union or discriminated union) holds a value of *one* of several alternatives. Its size is the *sum* of the sizes of the alternatives.

```typescript
type GestureKind =
  | 'idle'
  | 'pinch'
  | 'grab'
  | 'point'
```

### Discriminated Unions with a Tag Field

The most powerful pattern in TypeScript combines a literal `kind` field with distinct payload types:

```typescript
type GestureState =
  | { readonly kind: 'idle' }
  | { readonly kind: 'pinch'; readonly startTime: Timestamp; readonly hand: 'left' | 'right' }
  | { readonly kind: 'grab';  readonly startTime: Timestamp; readonly hand: 'left' | 'right' }
  | { readonly kind: 'point'; readonly hand: 'left' | 'right' }
```

TypeScript narrows the type automatically inside each `case` of a `switch`:

```typescript
const describeGesture = (g: GestureState): string => {
  switch (g.kind) {
    case 'idle':  return 'No gesture detected'
    case 'pinch': return `Pinch started at ${g.startTime} with ${g.hand} hand`
    case 'grab':  return `Grab started at ${g.startTime} with ${g.hand} hand`
    case 'point': return `Pointing with ${g.hand} hand`
  }
}
```

This is *exhaustive pattern matching*: if you add a new variant and forget to handle it, the compiler tells you.

### Actions as Sum Types

Domain actions are naturally modelled as sum types — a single type that captures every possible event:

```typescript
type Action =
  | { readonly kind: 'AddEntity';   readonly entity: Entity }
  | { readonly kind: 'RemoveEntity'; readonly id: EntityId }
  | { readonly kind: 'MoveEntity';  readonly id: EntityId; readonly delta: Vec3 }
  | { readonly kind: 'ScaleEntity'; readonly id: EntityId; readonly factor: Vec3 }
  | { readonly kind: 'RotateEntity'; readonly id: EntityId; readonly delta: Vec3 }
```

A reducer (pure function from `Universe × Action → Universe`) dispatches over this sum type:

```typescript
const applyAction = (universe: Universe, action: Action): Universe => {
  switch (action.kind) {
    case 'AddEntity':    return { ...universe, entities: [...universe.entities, action.entity] }
    case 'RemoveEntity': return { ...universe, entities: universe.entities.filter(e => e.id !== action.id) }
    // ...
  }
}
```

#### Exercises
1. Add a `'rotate'` variant to `GestureState` with a `hand` and `axis: Vec3` field.
2. Write the exhaustive `switch` for `Action` that logs a description of each action.
3. Why is a sum type safer than using a `string` field plus optional payload fields?

---

## Generic Types (Parametric Polymorphism)

Generics let you write a type that works for *any* type parameter, making abstractions reusable:

```typescript
type Option<A> = { readonly kind: 'none' } | { readonly kind: 'some'; readonly value: A }
type Result<A, E> = { readonly kind: 'ok'; readonly value: A } | { readonly kind: 'err'; readonly error: E }
```

`Option<A>` encodes the possibility of absence without resorting to `null` or `undefined`. `Result<A, E>` encodes success or failure with typed errors — both are used in `fp-ts` as `O.Option` and `E.Either`.

### Generic Functions

```typescript
const map = <A, B>(option: Option<A>, f: (a: A) => B): Option<B> => {
  if (option.kind === 'none') return { kind: 'none' }
  return { kind: 'some', value: f(option.value) }
}
```

The function signature guarantees that `f` is called only when a value is present. The compiler enforces this — no runtime null-checks needed.

### Utility Types

TypeScript ships with built-in generic types that transform existing types:

| Utility type       | Effect                                          |
|--------------------|-------------------------------------------------|
| `Readonly<T>`      | All properties become `readonly`                |
| `Partial<T>`       | All properties become optional                  |
| `Required<T>`      | All properties become required                  |
| `Record<K, V>`     | Object with keys of type `K` and values `V`     |
| `Pick<T, K>`       | Keep only the listed keys from `T`              |
| `Omit<T, K>`       | Remove the listed keys from `T`                 |
| `ReturnType<F>`    | Extract the return type of a function type      |
| `Parameters<F>`    | Extract the parameter types of a function type  |

```typescript
type PartialEntity = Partial<Entity>           // all fields optional — useful for patch updates
type ModelMap = Record<string, Model>          // maps model id → Model
type EntityTransform = Pick<Entity, 'position' | 'rotation' | 'scale'>
```

#### Exercises
1. Implement `flatMap` (also called `chain`) for `Option<A>`.
2. Use `Pick` to create an `EntityKey` type that contains only the `id` field of `Entity`.
3. Use `ReturnType` to derive the return type of `applyAction` without writing it explicitly.

---

## Function Types

Functions are first-class values in TypeScript. Their types are written with `=>`:

```typescript
type Transform<A, B> = (a: A) => B
type Predicate<A>    = (a: A) => boolean
type Reducer<S, A>   = (state: S, action: A) => S
```

### Function Composition

Two functions `f: A → B` and `g: B → C` compose to `g ∘ f: A → C`:

```typescript
const compose = <A, B, C>(g: (b: B) => C, f: (a: A) => B): (a: A) => C =>
  (a: A) => g(f(a))
```

This corresponds directly to morphism composition in category theory. The `pipe` function from `fp-ts` applies composition left-to-right, which often reads more naturally:

```typescript
import { pipe } from 'fp-ts/function'

const result = pipe(
  getApplicationCanvas(),   // Option<HTMLCanvasElement>
  O.map(createContext),     // Option<WebGL2RenderingContext>
  O.getOrElseW(() => { throw new Error('No canvas') })
)
```

### Currying and Partial Application

A curried function takes its arguments one at a time, returning a new function for each argument:

```typescript
const add = (a: number) => (b: number): number => a + b
const add5 = add(5)   // (b: number) => number
add5(3)               // 8
```

Curried functions compose well and enable partial application — you fix some arguments and get a specialised function back.

#### Exercises
1. Write a curried `scale` function `(factor: number) => (v: Vec3) => Vec3`.
2. Use `compose` to build a pipeline that: parses a raw string into a number, then multiplies by 2.
3. Rewrite `applyAction` in curried form so it can be partially applied with a `Universe`.

---

## Structural Typing and Type Compatibility

TypeScript uses **structural typing**: a value is compatible with a type if it has at least the required shape, regardless of how it was declared. This differs from nominal typing (Java, C#), where two types with the same fields are still distinct if declared separately.

```typescript
type Point2D = { x: number; y: number }
type Vector2D = { x: number; y: number }

const p: Point2D = { x: 1, y: 2 }
const v: Vector2D = p   // ✓ — same shape
```

### Type Narrowing

TypeScript narrows a union type inside conditional branches:

```typescript
const process = (input: string | number): string => {
  if (typeof input === 'string') {
    return input.toUpperCase()   // TypeScript knows input is string here
  }
  return input.toFixed(2)        // TypeScript knows input is number here
}
```

For discriminated unions, narrowing is done through the tag field (as shown in the `GestureState` example above).

### `as const` — Literal Types

```typescript
const GESTURE_KINDS = ['idle', 'pinch', 'grab', 'point'] as const
type GestureKind = typeof GESTURE_KINDS[number]   // 'idle' | 'pinch' | 'grab' | 'point'
```

`as const` freezes the inferred type to exact literal values, preventing widening to `string`.

#### Exercises
1. Declare a `HAND_SIDES` constant with `as const` and derive a `HandSide` type from it.
2. Write a type guard `isEntity(value: unknown): value is Entity` using structural checks.
3. Explain why two separately declared record types with identical fields are assignable to each other in TypeScript.

---

## Category Theory in the Type System

Category theory provides a mathematical language for composition. The core concepts map directly to TypeScript types and `fp-ts`.

### Category

A category consists of:
- **Objects** — types (`string`, `Entity`, `Universe`, …)
- **Morphisms** — functions between types (`(a: A) => B`)
- **Identity** — `const identity = <A>(a: A): A => a`
- **Composition** — associative function composition

Every TypeScript program is a category.

### Functor

A functor maps objects and morphisms from one category to another while preserving structure. In practical terms, a functor is a container type `F<A>` with a `map` function:

```typescript
// Signature of map for a generic functor F
map: <A, B>(fa: F<A>, f: (a: A) => B) => F<B>
```

Examples from `fp-ts`:
- `O.map(option, f)` — applies `f` if the `Option` is `Some`, leaves `None` unchanged
- `E.map(either, f)` — applies `f` if the `Either` is `Right`, propagates the `Left` error

```typescript
import * as O from 'fp-ts/Option'

const double = (n: number): number => n * 2

O.map(double)(O.some(21))   // O.some(42)
O.map(double)(O.none)       // O.none
```

`Array` is also a functor: `Array.map` applies a function to every element, producing a new array of the same length.

### Applicative

An applicative extends a functor with the ability to apply a wrapped function to a wrapped value:

```typescript
// ap: F<(a: A) => B> → F<A> → F<B>
```

This allows combining multiple independent effectful values (e.g., two `Option` values) without nesting `flatMap` calls.

### Monad

A monad is an applicative with a `flatMap` (also called `chain` in `fp-ts`) operation that sequences effects:

```typescript
// chain: (a: A) => F<B>  →  F<A>  →  F<B>
```

`E.chain` is used in `main.ts` to sequence shader creation steps, propagating errors without nested `if` checks:

```typescript
const vertexShader: WebGLShader = pipe(
  createVertexShader(gl),
  E.chain((vs) => initializeVertexShader(gl, vs)),
  E.match(
    (error) => { throw error },
    (vs) => vs
  )
)
```

The monad law of associativity ensures that `chain` can be refactored freely without changing meaning.

### Lens (Optics)

A lens (`monocle-ts`) is a composable getter/setter pair for immutable data structures. It lets you read or update a deeply nested field without spreading the entire state:

```typescript
import { Lens } from 'monocle-ts'

const positionLens = Lens.fromProp<Entity>()('position')

// Read
positionLens.get(entity)   // Vec3

// Immutable update
positionLens.set([1, 2, 3])(entity)   // returns a new Entity with updated position
```

Lenses compose: a lens into `Universe.entities[i]` composed with a lens into `Entity.position` gives a lens directly into the position of entity `i` in the universe.

#### Exercises
1. Implement `map` for `Result<A, E>` (apply `f` only to the `ok` value).
2. Use `E.chain` to sequence three operations: create a buffer, bind it, and upload data — each returning `E.Either<Error, T>`.
3. Define a `Lens` for `Universe` that focuses on the `entities` array.

---

## The Universe Type System

Bringing the theory together, here is the full type hierarchy of the application:

```typescript
// Primitives
type Scalar    = number
type EntityId  = string
type ModelId   = string
type Timestamp = number

// Algebra
type Vec2 = [Scalar, Scalar]
type Vec3 = [Scalar, Scalar, Scalar]
type Vec4 = [Scalar, Scalar, Scalar, Scalar]
type Mat4 = [Vec4, Vec4, Vec4, Vec4]

// Geometry
type Connection = [number, number]   // vertex index pair
type Model = {
  readonly id: ModelId
  readonly vertices: ReadonlyArray<Vec3>
  readonly connections: ReadonlyArray<Connection>
}

// Entities
type Entity = {
  readonly id: EntityId
  readonly modelId: ModelId
  readonly position: Vec3
  readonly rotation: Vec3
  readonly scale: Vec3
}

// Gesture FSM
type HandSide = 'left' | 'right'
type GestureState =
  | { readonly kind: 'idle' }
  | { readonly kind: 'pinch'; readonly hand: HandSide; readonly startTime: Timestamp }
  | { readonly kind: 'grab';  readonly hand: HandSide; readonly startTime: Timestamp }
  | { readonly kind: 'point'; readonly hand: HandSide }

// Layers
type NuclearState = {
  readonly entities: Readonly<Record<EntityId, Entity>>
  readonly gesture: GestureState
}

type GraphicsState = {
  readonly buffers: Readonly<Record<EntityId, WebGLBuffer>>
  readonly vaos: Readonly<Record<EntityId, WebGLVertexArrayObject>>
}

// The single source of truth
type Universe = {
  readonly nuclear: NuclearState
  readonly graphics: GraphicsState
  readonly models: Readonly<Record<ModelId, Model>>
}

// The tick morphism: Universe → Universe
type Tick = (universe: Universe) => Universe
```

Every frame is a morphism `Tick` — a pure function that transforms the universe. Effects (WebGL calls, XR frame submission) happen at the boundary, keeping the core logic pure and composable.

---

## Type-Level Patterns Reference

| Pattern                    | TypeScript construct                          | Use in this project                   |
|----------------------------|-----------------------------------------------|---------------------------------------|
| Type alias                 | `type EntityId = string`                      | Domain vocabulary                     |
| Product type               | `type Entity = { id: EntityId; … }`           | Compound domain objects                |
| Sum type / discriminated union | `type Action = \| { kind: 'Add'; … } \| …` | Events, gestures, actions             |
| Generic / parametric type  | `type Option<A> = …`                          | `fp-ts` Option, Either               |
| Utility type               | `Readonly<T>`, `Record<K,V>`                  | Immutable state, maps                 |
| Function type              | `type Tick = (u: Universe) => Universe`       | Layer morphisms, reducers             |
| Literal type               | `'left' \| 'right'`                           | Hand sides, gesture kinds             |
| Type narrowing             | `switch (action.kind) { … }`                  | Exhaustive dispatch on actions        |
| Lens / optic               | `Lens.fromProp<T>()(key)`                     | Immutable nested updates              |
| Functor map                | `O.map`, `E.map`, `Array.map`                 | Lifting pure functions into effects   |
| Monad chain                | `E.chain`, `O.chain`                          | Sequencing effectful operations       |

---

## Solutions to Exercises

### Fundamental Root
1. `type Milliseconds = number` makes the intent clear at call sites — a function `(t: Milliseconds)` signals it expects elapsed time, not an arbitrary number.
2. `never` is the empty set; it has no inhabitants. Use cases: the return type of a function that always throws, or the fallthrough of an exhaustive `switch` to catch missing cases.
3. `type StringNumberPair = [string, number]`

### Product Types
1. `type Transform = { readonly position: Vec3; readonly rotation: Vec3; readonly scale: Vec3 }`
2. A record with N fields contains values from each field's type simultaneously, so the total count of distinct values is the product of each field's count.
3. `readonly` fields produce a compile-time error if any code attempts to assign to them, enforcing immutability without a runtime cost.

### Sum Types
1. `| { readonly kind: 'rotate'; readonly hand: HandSide; readonly axis: Vec3 }`
2. Each `case` returns a descriptive string; TypeScript reports a type error if a variant is omitted.
3. A dedicated `kind` discriminant is always present; optional payload fields could accidentally mix fields from different variants without the compiler detecting it.

### Generic Types
1. `const flatMap = <A, B>(option: Option<A>, f: (a: A) => Option<B>): Option<B> => option.kind === 'none' ? { kind: 'none' } : f(option.value)`
2. `type EntityKey = Pick<Entity, 'id'>`
3. `type NewUniverse = ReturnType<typeof applyAction>`

### Function Types
1. `const scale = (factor: number) => ([x, y, z]: Vec3): Vec3 => [x * factor, y * factor, z * factor]`
2. `const pipeline = compose((n: number) => n * 2, (s: string) => Number(s))`
3. `const applyAction = (universe: Universe) => (action: Action): Universe => { … }`

### Structural Typing
1. `const HAND_SIDES = ['left', 'right'] as const; type HandSide = typeof HAND_SIDES[number]`
2. Check for the presence and types of required fields inside the guard function using `typeof` and `in`.
3. TypeScript checks shape, not declaration origin; two types with identical fields satisfy each other's constraints.

### Category Theory
1. `const map = <A, E, B>(result: Result<A, E>, f: (a: A) => B): Result<B, E> => result.kind === 'err' ? result : { kind: 'ok', value: f(result.value) }`
2. Chain `createBuffer`, `bindBuffer`, and `uploadData`, each returning `E.Either<Error, T>`, using `pipe` and `E.chain`.
3. `const entitiesLens = Lens.fromProp<Universe>()('nuclear').compose(Lens.fromProp<NuclearState>()('entities'))`
