# Category Theory for Software Architecture: A Conceptual Tree

## Vision and Purpose

This document is a comprehensive guide to category theory applied to software architecture and functional programming, structured as a conceptual tree. Each section builds upon the previous, allowing for a deep and progressive understanding of the mathematics behind composable systems. The goal is for you to analyze, compose, and create your own abstractions, using category theory as a reasoning tool rather than a mere implementation detail.

The concepts here map directly to the architecture of this project: the `Universe` object, the layer morphisms, the `Result`/`Either` error handling, the `Action` coproducts, and the `pipe`/`compose` patterns used throughout the TypeScript codebase.

---

## Visión y Propósito

Este documento es una guía exhaustiva sobre teoría de categorías aplicada a arquitectura de software y programación funcional, estructurada como un árbol conceptual. Cada sección se construye sobre la anterior, permitiendo una comprensión profunda y progresiva de las matemáticas detrás de los sistemas componibles. El objetivo es que puedas analizar, componer y crear tus propias abstracciones, usando la teoría de categorías como herramienta de razonamiento más que como un simple detalle de implementación.

Los conceptos aquí se mapean directamente a la arquitectura de este proyecto: el objeto `Universe`, los morfismos entre capas, el manejo de errores con `Result`/`Either`, los coproductos `Action`, y los patrones `pipe`/`compose` usados a lo largo del código TypeScript.

---

## Fundamental Root: Categories

### What is a category?

A category `C` consists of three things:

1. **A collection of objects** — these are not necessarily sets; they are abstract entities.
2. **A collection of morphisms (arrows)** — for every pair of objects `A` and `B`, there is a (possibly empty) set of morphisms `Hom(A, B)` from `A` to `B`.
3. **A composition operation** — for morphisms `f: A → B` and `g: B → C`, there exists a composed morphism `g ∘ f: A → C`.

#### The two laws of a category

Every category must satisfy exactly two laws:

**Identity:** For every object `A`, there exists an identity morphism `id_A: A → A` such that for any morphism `f: A → B`:
```
f ∘ id_A = f    (right identity)
id_B ∘ f = f    (left identity)
```

**Associativity:** For morphisms `f: A → B`, `g: B → C`, and `h: C → D`:
```
h ∘ (g ∘ f) = (h ∘ g) ∘ f
```

#### Examples of categories

- **Set**: objects are sets, morphisms are functions between sets.
- **Hask** (Haskell types): objects are types, morphisms are functions.
- **TypeScript types**: objects are TypeScript types, morphisms are typed functions.
- **A single object category (monoid)**: one object, morphisms are the monoid elements composed by the monoid operation.
- **A poset (partially ordered set)**: objects are elements, there is a morphism `a → b` if and only if `a ≤ b`.

#### In this project

In the codebase, the category is **TypeScript types**:
- Objects: `Universe`, `Model`, `Entity`, `GestureState`, `GraphicsState`, etc.
- Morphisms: pure functions such as `addModel`, `addEntity`, `moveVertex`, `applyAction`.
- Identity: the `identity` function `(x) => x`.
- Composition: the `pipe` and `compose` utilities from `fp-ts/function`.

```typescript
import { pipe } from 'fp-ts/function'

// Morphism: Universe -> Universe
const addModel = (m: Model) => (u: Universe): Universe => ({
  ...u,
  models: [m, ...u.models]
})

// Morphism: Universe -> Universe
const addEntity = (e: Entity) => (u: Universe): Universe => ({
  ...u,
  entities: [e, ...u.entities]
})

// Composed morphism: Universe -> Universe
const updateUniverse = (m: Model, e: Entity) => (u: Universe): Universe =>
  pipe(u, addModel(m), addEntity(e))
```

#### Exercises
1. Name three objects and two morphisms in the TypeScript category.
2. Verify the right-identity law for the function `addModel` and `identity`.
3. Verify associativity for a chain of three `Universe -> Universe` functions.
4. Give an example of a category with exactly one morphism between any two distinct objects.

---

## First Branch: Morphisms

### Types of morphisms

| Name | Definition | Example |
|------|-----------|---------|
| **Monomorphism (mono)** | `f: A → B` is mono if `f ∘ g = f ∘ h` implies `g = h` (injective in Set) | `addModel` (adds without replacing) |
| **Epimorphism (epi)** | `f: A → B` is epi if `g ∘ f = h ∘ f` implies `g = h` (surjective in Set) | A mapping onto all entity IDs |
| **Isomorphism** | `f: A → B` with an inverse `g: B → A` where `g ∘ f = id_A` and `f ∘ g = id_B` | Serialise/deserialise a `Universe` to/from JSON |
| **Endomorphism** | `f: A → A` (same source and target) | Any `Universe -> Universe` tick function |
| **Automorphism** | An isomorphism that is also an endomorphism | A rotation that maps a space to itself |

#### In this project

Every application tick is an **endomorphism** on `Universe`:
```typescript
type Tick = (universe: Universe) => Universe
```

The composition of ticks is still a `Tick`, which is why the pipeline is easy to extend.

#### Exercises
1. Is the function `moveVertex` a monomorphism? Justify your answer.
2. Give an example of an isomorphism involving `Model` serialisation.
3. Compose two `Tick` endomorphisms and verify the result is also a `Tick`.

---

## Second Branch: Functors

### What is a functor?

A **functor** `F: C → D` is a mapping between two categories that:

1. Maps every object `A` in `C` to an object `F(A)` in `D`.
2. Maps every morphism `f: A → B` in `C` to a morphism `F(f): F(A) → F(B)` in `D`.

And it must preserve the category structure:

- **Identity:** `F(id_A) = id_{F(A)}`
- **Composition:** `F(g ∘ f) = F(g) ∘ F(f)`

#### Endofunctors

An **endofunctor** maps a category to itself: `F: C → C`. In programming, most functors are endofunctors on the category of types.

A type `F<A>` is a functor if it supports a `map` operation:
```typescript
map: <A, B>(f: (a: A) => B) => (fa: F<A>) => F<B>
```

#### Common functor instances

| Functor | `F<A>` | `map(f)(fa)` behaviour |
|---------|--------|------------------------|
| `Array` | `A[]` | Apply `f` to each element |
| `Option` | `Some(a)` or `None` | Apply `f` if `Some`, skip if `None` |
| `Either` | `Right(a)` or `Left(e)` | Apply `f` if `Right`, skip if `Left` |
| `Task` | `() => Promise<A>` | Apply `f` to the resolved value |

#### In this project

The `mapVertices` function from `DESIGN.md` is a **functor map** for `Model`:

```typescript
// Model is a functor over Vertex
const mapVertices = (f: (v: Vertex) => Vertex) => (model: Model): Model => ({
  ...model,
  vertices: model.vertices.map(f)
})

// Example: scale all vertices by a factor
const scaleVertices = (factor: number) =>
  mapVertices(([x, y, z]) => [x * factor, y * factor, z * factor])
```

The `fp-ts` library's `Option` and `Either` are used throughout `main.ts`:

```typescript
import * as O from 'fp-ts/Option'
import * as E from 'fp-ts/Either'

// Option functor: map over a value that may not exist
const maybeModel: O.Option<Model> = O.some(myModel)
const maybeVertexCount = O.map((m: Model) => m.vertices.length)(maybeModel)
// => O.some(42) or O.none
```

#### Exercises
1. Show that `Array` satisfies the functor identity law: `map(id) = id`.
2. Show that `Array` satisfies the functor composition law: `map(g ∘ f) = map(g) ∘ map(f)`.
3. Implement a `mapModels` functor for `Universe` that applies a function to every `Model`.
4. Is `mapVertices` an endofunctor? Justify your answer.
5. Give an example of a type that looks like a functor but violates one of the laws.

---

## Third Branch: Natural Transformations

### What is a natural transformation?

Given two functors `F, G: C → D`, a **natural transformation** `η: F → G` assigns to every object `A` in `C` a morphism `η_A: F(A) → G(A)` in `D`, such that for every morphism `f: A → B` in `C`:

```
G(f) ∘ η_A = η_B ∘ F(f)
```

This is called the **naturality condition** and means the transformation commutes with the functor mappings.

#### Intuition

A natural transformation is a "family of morphisms" — one for each type — that is consistent with how both functors transform morphisms. In programming, it is any function of the form:

```typescript
// η: F<A> -> G<A>  for all A, without depending on A's specific structure
type NatTrans<F, G> = <A>(fa: F<A>) => G<A>
```

#### Examples

- `Array → Option`: take the first element (or `None` if empty).
- `Option → Array`: convert `Some(a)` to `[a]` and `None` to `[]`.
- `Either → Option`: forget the error, keep only the success value.

```typescript
// Natural transformation: Option<A> -> A[]
const optionToArray = <A>(oa: O.Option<A>): A[] =>
  O.isNone(oa) ? [] : [oa.value]

// Natural transformation: A[] -> Option<A> (head)
const arrayHead = <A>(arr: A[]): O.Option<A> =>
  arr.length === 0 ? O.none : O.some(arr[0])
```

#### In this project

The conversion from a raw WebXR `XRJointPose` to the internal `Vertex` type is a natural transformation between the WebXR data functor and the domain data functor:

```typescript
// η: XRJointPose -> Vertex  (applied point-wise in the hand joint array)
const jointPoseToVertex = (pose: XRJointPose): Vertex => [
  pose.transform.position.x,
  pose.transform.position.y,
  pose.transform.position.z
]
```

#### Exercises
1. Write the naturality square diagram for `optionToArray`.
2. Verify that `arrayHead` followed by `optionToArray` returns an array of at most one element.
3. Is a constant function `(_: F<A>) => G<A>` always a natural transformation? Why or why not?

---

## Fourth Branch: Monads

### What is a monad?

A **monad** is a triple `(M, return, bind)` where:

- `M` is an endofunctor: `M: C → C`
- `return` (also called `unit` or `pure`): `A → M(A)` — wraps a value
- `bind` (also written `>>=`): `M(A) → (A → M(B)) → M(B)` — sequences computations

The three **monad laws** must hold:

```
-- Left identity
return a >>= f  =  f a

-- Right identity
m >>= return  =  m

-- Associativity
(m >>= f) >>= g  =  m >>= (\x -> f x >>= g)
```

#### Intuition

A monad is a pattern for chaining computations that carry some context (optionality, error handling, asynchrony, state, logging, etc.). Each step can decide whether to continue the chain or short-circuit.

#### Common monad instances

| Monad | Context | Short-circuit condition |
|-------|---------|------------------------|
| `Option` | Optional value | `None` |
| `Either<E, A>` | Fallible computation | `Left(error)` |
| `Task<A>` | Asynchronous computation | Promise rejection |
| `State<S, A>` | Stateful computation | — (no short-circuit) |
| `Array<A>` | Non-determinism | Empty array |

#### In this project

The `Result` type in `DESIGN.md` is a `Either`-style monad for error handling:

```typescript
// Haskell definition from DESIGN.md translated to TypeScript
type Result<A> = { _tag: 'Ok'; value: A } | { _tag: 'Error'; message: string }

const ok = <A>(value: A): Result<A> => ({ _tag: 'Ok', value })
const error = (message: string): Result<never> => ({ _tag: 'Error', message })

// bind: the monadic chain operator
const bind = <A, B>(
  result: Result<A>,
  f: (a: A) => Result<B>
): Result<B> =>
  result._tag === 'Ok' ? f(result.value) : result

// Example: chain of fallible WebGL operations
const initGL = (canvas: HTMLCanvasElement): Result<WebGL2RenderingContext> =>
  canvas.getContext('webgl2')
    ? ok(canvas.getContext('webgl2')!)
    : error('WebGL2 not supported')

const compileShader = (gl: WebGL2RenderingContext): Result<WebGLProgram> => {
  // ... compile and return Ok(program) or Error(message)
  return ok(gl.createProgram()!)
}

const pipeline = (canvas: HTMLCanvasElement): Result<WebGLProgram> =>
  bind(initGL(canvas), compileShader)
```

Using `fp-ts`:

```typescript
import * as E from 'fp-ts/Either'
import { pipe } from 'fp-ts/function'

const pipeline = (canvas: HTMLCanvasElement) =>
  pipe(
    E.tryCatch(() => canvas.getContext('webgl2')!, (e) => `Context error: ${e}`),
    E.chain((gl) => E.right(gl))  // continue the chain
  )
```

#### Exercises
1. Verify the left-identity monad law for `Result`/`Either`.
2. Verify the right-identity monad law for `Option`.
3. Implement `sequence: Result<A>[] -> Result<A[]>` using `bind` — it succeeds only if every element succeeds.
4. Why is `Array` a monad? What does `bind` mean for arrays (hint: `flatMap`)?
5. Refactor a chain of three nullable WebGL calls using `Option`'s monadic chain.

---

## Fifth Branch: Algebraic Data Types

### Product types

A **product type** `A × B` contains a value of type `A` *and* a value of type `B` simultaneously. In TypeScript, product types are records or tuples:

```typescript
// Tuple (product)
type Vec2 = [number, number]
type Vec3 = [number, number, number]

// Record (named product)
type Model = {
  modelId: string        // String
  vertices: Vertex[]     // [Vertex]
  connections: Connection[]  // [Connection]
  geometry: Geometry
}
```

The `Model` type is a product of `String`, `[Vertex]`, `[Connection]`, and `Geometry`.

**Cardinality:** `|A × B| = |A| × |B|` — the number of inhabitants is the product of inhabitants of each component.

### Sum types (coproducts)

A **sum (coproduct) type** `A + B` contains a value of type `A` *or* a value of type `B`, but never both. In TypeScript, this is a discriminated union:

```typescript
// From DESIGN.md
type Geometry =
  | { _tag: 'Polygon'; sides: number }
  | { _tag: 'Mesh'; faces: number }
  | { _tag: 'Custom'; description: string }

// Action coproduct from DESIGN.md
type Action =
  | { _tag: 'AddModel'; model: Model }
  | { _tag: 'AddEntity'; entity: Entity }
  | { _tag: 'MoveVertex'; modelIndex: number; delta: Vec3; vertexIndex: number }
```

**Cardinality:** `|A + B| = |A| + |B|`.

### Why algebraic types matter

Algebraic data types (ADTs) make **illegal states unrepresentable**. If a gesture is always exactly one of `{ Idle, Pinching, Grabbing }`, a sum type enforces this at compile time.

They also guide **exhaustive pattern matching**: the compiler warns when a `switch` or `if`-chain does not handle all variants of a sum type.

```typescript
const applyAction = (action: Action) => (universe: Universe): Universe => {
  switch (action._tag) {
    case 'AddModel':   return { ...universe, models: [action.model, ...universe.models] }
    case 'AddEntity':  return { ...universe, entities: [action.entity, ...universe.entities] }
    case 'MoveVertex': return { /* ... */ }
    // TypeScript error if a new variant is added and not handled here
  }
}
```

#### Exercises
1. Calculate the cardinality of `type Bit = 0 | 1`. What kind of ADT is this?
2. Write a sum type for the gesture finite-state machine with states: `Idle`, `Pinching`, `Grabbing`, and `Pointing`.
3. Write a product type for a `Transform` that bundles position, rotation, and scale.
4. Which ADT — product or sum — is more appropriate for an HTTP response that is either a success body or an error message? Justify your answer.
5. Explain why `Option<A>` is equivalent to `() + A` (the unit type plus `A`).

---

## Sixth Branch: Composition Patterns

### Function composition

The most basic categorical operation is **composition**:

```typescript
// (b -> c) -> (a -> b) -> (a -> c)
const compose = <A, B, C>(g: (b: B) => C) => (f: (a: A) => B) => (a: A): C => g(f(a))

// Left-to-right composition (pipe)
const andThen = <A, B, C>(f: (a: A) => B) => (g: (b: B) => C) => (a: A): C => g(f(a))
```

`fp-ts` provides both:

```typescript
import { flow, pipe } from 'fp-ts/function'

// flow = left-to-right composition of functions
const scaleAndTranslate = flow(
  scaleVertices(2),
  translateVertices([1, 0, 0])
)

// pipe = apply transformations left-to-right to a value
const newUniverse = pipe(
  initialUniverse,
  addModel(cubeModel),
  addEntity(playerEntity),
  applyAction({ _tag: 'MoveVertex', modelIndex: 0, delta: [0, 1, 0], vertexIndex: 3 })
)
```

### The pipeline as a category

A **processing pipeline** is itself a category:
- Objects are the intermediate state types.
- Morphisms are the processing steps.
- Composition is sequential application.

```
InputLayer → NuclearLayer → GraphicsLayer → XRLayer → DisplayLayer
```

Each arrow is a morphism. The whole pipeline is their composition. Adding or removing a step is adding or removing a morphism — without changing the others.

### Kleisli composition

When morphisms return monadic values `A → M(B)`, ordinary composition no longer works. **Kleisli composition** handles this:

```typescript
// Kleisli composition for Either
const composeK =
  <A, B, C, E>(f: (a: A) => E.Either<E, B>) =>
  (g: (b: B) => E.Either<E, C>) =>
  (a: A): E.Either<E, C> =>
    pipe(f(a), E.chain(g))

// Example: chain two fallible WebGL initialisations
const initAndCompile = composeK(initGL)(compileShader)
```

#### Exercises
1. Implement `flow` (left-to-right composition) using only `compose`.
2. Verify that `pipe(u, f, g)` equals `compose(g)(f)(u)`.
3. Write a Kleisli composition for `Option`.
4. Model the application tick pipeline as a category: name all objects (state types) and morphisms (processing functions).

---

## Seventh Branch: Lenses and Optics

### The problem of immutable nested updates

Updating deeply nested immutable structures requires threading changes up through every layer:

```typescript
// Without lenses — verbose and error-prone
const newUniverse: Universe = {
  ...universe,
  nuclearState: {
    ...universe.nuclearState,
    entities: universe.nuclearState.entities.map((e) =>
      e.entityId === id ? { ...e, position: newPosition } : e
    )
  }
}
```

### What is a lens?

A **lens** `Lens<S, A>` focuses on a part `A` inside a whole `S`. It provides:
- `get: (s: S) => A` — read the focused part.
- `set: (a: A) => (s: S) => S` — write the focused part immutably.

Lenses compose: `Lens<S, A>` composed with `Lens<A, B>` gives `Lens<S, B>`.

```typescript
import * as L from 'monocle-ts/Lens'

// Lens focusing on the models array within Universe
const modelsLens = L.fromProp<Universe>()('models')

// Composed lens: Universe -> first Model -> vertices
const firstModelVerticesLens = pipe(
  modelsLens,
  L.composeTraversal(/* ... */)
)
```

### Category theory behind lenses

A `Lens<S, A>` is a morphism in the category of lenses, where:
- Objects are types.
- Morphisms are `(get, set)` pairs satisfying coherence laws.

The three lens laws are:
1. `get(set(a)(s)) = a` — getting after setting returns what was set.
2. `set(get(s))(s) = s` — setting what is already there is a no-op.
3. `set(a)(set(b)(s)) = set(a)(s)` — the second set overwrites the first.

#### In this project

`monocle-ts` (a dependency in `package.json`) provides composable lenses for all nested state updates:

```typescript
// monocle-ts example for this project
import { Lens } from 'monocle-ts'

const universeLens = Lens.fromProp<Universe>()
const entitiesLens = universeLens('entities')
const modelsLens   = universeLens('models')
```

#### Exercises
1. Verify the three lens laws for a lens on a simple `{ x: number }` record.
2. Compose two lenses: one from `Universe` to `nuclearState`, and one from `nuclearState` to `gestureState`.
3. How would you implement `modify: (f: A => A) => (s: S) => S` from `get` and `set`?
4. What is a **prism** (a related optic)? How does it differ from a lens? Give an example involving the `Geometry` sum type.

---

## Eighth Branch: The Curry–Howard Correspondence

### Types as propositions, programs as proofs

The **Curry–Howard correspondence** is an isomorphism between:

| Type theory | Logic | Category theory |
|-------------|-------|-----------------|
| Type `A` | Proposition `A` | Object |
| Value `a: A` | Proof of `A` | Global element |
| Function `A → B` | Implication `A ⇒ B` | Morphism |
| Product `A × B` | Conjunction `A ∧ B` | Product object |
| Sum `A \| B` | Disjunction `A ∨ B` | Coproduct |
| `never` | False (`⊥`) | Initial object |
| `void` / `()` | True (`⊤`) | Terminal object |
| `Option<A>` | `A ∨ ⊤` (optionally `A`) | — |

#### Practical implications

- A **type signature** is a theorem statement.
- A **correct implementation** is a proof of that theorem.
- A **type error** is a proof failure.
- Making **illegal states unrepresentable** means encoding invariants as logical propositions.

#### Example

```typescript
// This type signature is the theorem:
// "Given a Universe and an Action, I can produce a new Universe"
// The implementation is the proof.
declare const applyAction: (action: Action) => (universe: Universe) => Universe
```

#### Exercises
1. What logical proposition corresponds to `(A | B) → C`? (Hint: it is a conjunction of two implications.)
2. Translate the monad bind type `M<A> → (A → M<B>) → M<B>` to a logical formula.
3. What does the `never` type represent logically? Give an example of when it appears.
4. Use the correspondence to explain why a function of type `(f: (a: A) => B, g: (b: B) => C) => (a: A) => C` is always implementable, but `(f: (a: A) => B) => A` is not.

---

## Ninth Branch: Applications

### In this project (manas)

| Category theory concept | Application |
|------------------------|-------------|
| Category (TypeScript types + functions) | The whole type system and function space |
| Object | `Universe`, `Model`, `Entity`, `GestureState`, `GraphicsState` |
| Morphism (endomorphism) | Each application tick: `Universe → Universe` |
| Composition | `pipe`, `flow` from `fp-ts/function` |
| Functor | `mapVertices`, `Option.map`, `Either.map` |
| Natural transformation | `jointPoseToVertex`, `Either → Option` conversions |
| Monad | `Either` for WebGL error handling, `Task` for async model loading |
| Product type | `Model`, `Transform`, `Universe` |
| Sum type (coproduct) | `Action`, `Geometry`, `GestureKind` |
| Lens | `monocle-ts` lenses for immutable state updates |
| Kleisli composition | Chaining fallible WebGL initialisations |

### In computer science

- **Type systems**: algebraic data types, parametric polymorphism.
- **Functional programming**: monads for I/O, state, and error handling.
- **Compiler design**: functors over abstract syntax trees (ASTs).
- **Database theory**: relational algebra as a category.
- **Concurrency**: monoidal categories for parallel composition.

### In mathematics

- **Topology**: continuous maps between topological spaces form a category.
- **Algebra**: group homomorphisms form a category.
- **Logic**: propositions and proofs form a category (Curry–Howard).
- **Geometry**: smooth manifolds and smooth maps form a category.

### In other domains

- **Physics**: physical systems as objects, processes as morphisms (string diagrams).
- **Linguistics**: grammatical structures as functors over syntax trees.
- **Systems biology**: interaction networks modelled as categories.
- **Economics**: resource flow networks as monoidal categories.

---

## Solutions to Exercises

### Categories
1. Objects: `number`, `string`, `Model`. Morphisms: `(n: number) => string`, `(s: string) => Model`.
2. `addModel(m)(identity(u)) = addModel(m)(u) = addModel(m)(u)` ✓
3. `(h ∘ g) ∘ f` and `h ∘ (g ∘ f)` both equal `(u) => h(g(f(u)))` ✓
4. The indiscrete category: one morphism `f: A → B` for each pair, forced by the identity to be unique.

### Morphisms
1. `moveVertex` is not necessarily a monomorphism — two different moves could produce the same result if the vertex is at the boundary. In practice for real-number coordinates it is injective.
2. `serialize: Model → string` and `deserialize: string → Model` (for valid JSON) form an isomorphism on the subset of valid strings.
3. `(u: Universe) => tick2(tick1(u))` is again a `Tick` by closure of function composition.

### Functors
1. `map(id)(arr) = arr.map(x => x) = arr` ✓
2. `map(g ∘ f)(arr) = arr.map(x => g(f(x))) = arr.map(f).map(g) = (map(g) ∘ map(f))(arr)` ✓
3. `const mapModels = (f: (m: Model) => Model) => (u: Universe) => ({ ...u, models: u.models.map(f) })`
4. Yes — `mapVertices: (Vertex → Vertex) → Model → Model` maps within the single category of TypeScript types.
5. A set with a "map" that does not preserve composition: e.g., `map(f)(arr) = []` (constant empty) fails both laws.

### Natural transformations
1. The naturality square: for any `f: A → B`, `optionToArray(Option.map(f)(oa))` equals `Array.map(f)(optionToArray(oa))`.
2. `arrayHead` returns at most one element; `optionToArray` converts it to an array of 0 or 1 elements ✓
3. No — a constant natural transformation `(_) => emptyG` satisfies naturality only if `G(f) ∘ η = η ∘ F(f)` reduces to `emptyG = emptyG`, which holds; but it is a valid (trivial) natural transformation.

### Monads
1. `bind(return(a), f) = bind(Ok(a), f) = f(a)` ✓
2. `bind(Some(a), return) = return(a) = Some(a)` and `bind(None, return) = None` ✓
3. `const sequence = <A>(results: Result<A>[]): Result<A[]> => results.reduce((acc, r) => bind(acc, (arr) => bind(r, (v) => ok([...arr, v]))), ok([]))`
4. `Array` is a monad where `bind = flatMap` — it models non-determinism: each element spawns a new list of possibilities.
5. Use `O.chain` from `fp-ts/Option` to chain three nullable WebGL lookups.

### Algebraic Data Types
1. `|Bit| = 2`. It is a sum type (`0 | 1`).
2. `type GestureKind = { _tag: 'Idle' } | { _tag: 'Pinching' } | { _tag: 'Grabbing' } | { _tag: 'Pointing' }`
3. `type Transform = { position: Vec3; rotation: Vec4; scale: Vec3 }`
4. Sum type — an HTTP response is either a success *or* an error, never both simultaneously.
5. `Option<A> ≅ None | Some(A) ≅ () + A` because `None` carries no information (unit) and `Some` carries exactly one `A`.

### Composition Patterns
1. `const flow = (f, g) => compose(g)(f)`
2. `pipe(u, f, g) = g(f(u)) = compose(g)(f)(u)` ✓
3. `const composeKOption = (f) => (g) => (a) => O.chain(g)(f(a))`
4. Objects: `RawInput`, `NuclearState`, `GraphicsState`, `XRFrame`, `RenderedFrame`. Morphisms: each processing layer function.

### Lenses
1. `get(set(a)(s)) = a` ✓; `set(get(s))(s) = s` ✓; `set(a)(set(b)(s)) = set(a)(s)` ✓
2. `const gestureStateLens = pipe(nuclearStateLens, L.prop('gestureState'))`
3. `const modify = (f) => (s) => set(f(get(s)))(s)`
4. A **prism** focuses on one variant of a sum type. Example: `Prism<Geometry, number>` targeting only the `Polygon` variant to read/write the number of sides.

### Curry–Howard
1. `(A | B) → C` corresponds to `(A ∨ B) ⇒ C`, which is logically equivalent to `(A ⇒ C) ∧ (B ⇒ C)`.
2. `M<A> → (A → M<B>) → M<B>` corresponds to `□A → (A → □B) → □B` (in modal logic, the monadic axiom).
3. `never` is the bottom type (⊥ / False). It appears as the return type of functions that never return, e.g., `throw` or infinite loops.
4. `(f, g) => (a) => g(f(a))` is always implementable (it is the composition proof `A ⇒ B, B ⇒ C ⊢ A ⇒ C`). But `(f: A → B) => A` would require producing an `A` out of nothing — the logical formula `(A ⇒ B) ⇒ A` is not a tautology.
