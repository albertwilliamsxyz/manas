# Homotopy + Dependent Type Theory: A Conceptual Tree

## Vision and Purpose

This document explores dependent type theory and homotopy type theory (HoTT) as mathematical frameworks for reasoning about programs, proofs, and spaces. It builds on the categorical foundation already present in this project and shows how types can be understood not merely as sets of values, but as spaces with rich geometric structure. The goal is to give you the tools to reason about identity, equivalence, and composition at a deeper level—both in your type system and in the mathematics that underlies it.

---

## Visión y Propósito

Este documento explora la teoría de tipos dependientes y la teoría de tipos homotópica (HoTT) como marcos matemáticos para razonar sobre programas, pruebas y espacios. Se construye sobre la base categórica ya presente en este proyecto y muestra cómo los tipos pueden entenderse no solo como conjuntos de valores, sino como espacios con estructura geométrica rica. El objetivo es darte las herramientas para razonar sobre identidad, equivalencia y composición a un nivel más profundo, tanto en tu sistema de tipos como en las matemáticas que lo sustentan.

---

## Fundamental Root: Types as Propositions, Types as Spaces

### The Curry–Howard Correspondence

At the heart of dependent type theory lies the **Curry–Howard correspondence**, also called the propositions-as-types or proofs-as-programs interpretation:

| Logic                  | Type Theory             | Homotopy                  |
|------------------------|-------------------------|---------------------------|
| Proposition            | Type                    | Space                     |
| Proof                  | Term / Program          | Point in a space          |
| True proposition       | Inhabited type          | Non-empty space           |
| False proposition      | Empty type (`Never`)    | Empty space               |
| Implication `A → B`    | Function type `A -> B`  | Continuous map            |
| Conjunction `A ∧ B`    | Product type `A × B`    | Product space             |
| Disjunction `A ∨ B`    | Sum type `A | B`        | Coproduct / disjoint union|
| Universal `∀ x, P(x)` | Dependent function `Π`  | Fibration                 |
| Existential `∃ x, P(x)`| Dependent pair `Σ`     | Total space of a fibration|

This triplе correspondence—logic, types, homotopy—is the conceptual core of HoTT.

#### Examples
- The proposition "there exists a vertex at the origin" becomes a type `Σ (v : Vertex), v = origin`.
- The proposition "every entity has a valid id" becomes a function type `(e : Entity) → isValid(e.id)`.
- The type `A → B` is both a function from `A` to `B` and a proof that `A` implies `B`.

#### Exercises
1. Translate the proposition "every model has at least one vertex" into a dependent type.
2. What does an inhabitant (a term) of the type `A × B` represent in logic?
3. What type corresponds to "A is false" (i.e., A implies absurdity)?

---

## First Branch: Dependent Types

### What is a Dependent Type?

A **dependent type** is a type that depends on a value. In ordinary type systems, types and values live in separate worlds. In a dependent type system, types can be computed from values, enabling far more precise specifications.

#### Pi Types (Dependent Function Types) — `Π`

`Π (x : A), B(x)` is the type of functions that take a value `x` of type `A` and return a value of type `B(x)`, where the return type `B(x)` may depend on the input `x`.

When `B` does not depend on `x`, `Π (x : A), B` is simply `A → B`.

```typescript
// Ordinary function: return type does not depend on input
type Id = (x: number) => number;

// Dependent function (approximated in TypeScript with generics):
// The return type depends on the input type
type Replicate = <N extends number>(n: N, x: string) => string[];

// A tighter approximation using conditional types:
type Head<T extends unknown[]> = T extends [infer H, ...unknown[]] ? H : never;
```

#### Sigma Types (Dependent Pair Types) — `Σ`

`Σ (x : A), B(x)` is the type of pairs `(a, b)` where `a : A` and `b : B(a)`. The type of the second component depends on the value of the first.

```typescript
// A pair where the second component's type depends on the first:
// (approximated in TypeScript)
type EntityWithId<Id extends string> = { id: Id; data: Record<string, unknown> };

// A dependent pair: a vertex together with a proof it lies in the unit cube
// In Agda/Coq:  Σ (v : Vec3), (0 ≤ v.x ≤ 1) × (0 ≤ v.y ≤ 1) × (0 ≤ v.z ≤ 1)
type BoundedVertex = {
  vertex: [number, number, number];
  bounded: true; // evidence that the constraint holds (simplified)
};
```

#### Examples
- `Π (n : Nat), Vec n Float` — a function from a natural number to a vector of exactly that length.
- `Σ (m : Model), m.vertices.length > 0` — a model together with evidence it is non-empty.
- `Π (e : Entity), Σ (m : Model), referencedBy(e, m)` — for every entity, a model it references.

#### Exercises
1. Write a Π type for a function that, given a natural number `n`, returns an array of exactly `n` vertices.
2. Write a Σ type for a pair of an entity ID and a proof that the ID is non-empty.
3. How does `Σ (x : A), B(x)` differ from the product type `A × B`?

---

## Second Branch: Identity Types and Path Equality

### The Identity Type

In dependent type theory, equality between two terms `a` and `b` of type `A` is itself a type, written `Id_A(a, b)` or `a =_A b`. A term of this type is a **proof of equality**, not just a boolean.

- `refl : a =_A a` — every element is equal to itself (reflexivity is a term, not just an axiom).
- Equality can be transported: if `a = b` and `P(a)` holds, then `P(b)` holds.
- Equality can be composed: if `a = b` and `b = c`, then `a = c`.

```typescript
// TypeScript approximation using conditional types:
type Equal<A, B> = A extends B ? (B extends A ? true : false) : false;

// In a richer system (pseudocode):
// refl : (a : A) → Id A a a
// sym  : Id A a b → Id A b a
// trans: Id A a b → Id A b c → Id A a c
// subst: Id A a b → P(a) → P(b)
```

### The Homotopic Interpretation of Identity

The key insight of HoTT is that **identity proofs are paths**:

- A type `A` is interpreted as a **topological space**.
- A term `a : A` is a **point** in that space.
- A proof `p : a = b` is a **path** from `a` to `b` in the space.
- A proof `H : p = q` (two paths are equal) is a **homotopy** — a continuous deformation of one path into another.
- Higher equalities give higher-dimensional structure: 2-paths, 3-paths, and so on.

This infinite tower of higher equalities is what makes HoTT a **higher-dimensional** type theory.

```
Point a ──── path p ────► Point b
              ‖
         homotopy H
              ‖
Point a ──── path q ────► Point b
```

#### Path Operations

| Operation   | Type                                  | Meaning                         |
|-------------|---------------------------------------|---------------------------------|
| `refl`      | `a = a`                               | Constant path (identity)        |
| `sym(p)`    | `a = b → b = a`                       | Reverse path                    |
| `trans(p,q)`| `a = b → b = c → a = c`              | Concatenation of paths          |
| `ap(f, p)`  | `a = b → f(a) = f(b)`                | Apply function to both endpoints|
| `subst(p,t)`| `a = b → P(a) → P(b)`               | Transport along a path          |

#### Examples
- A rotation by 360° is a path from the identity to itself in the space of rotations — homotopically non-trivial.
- Two transformation matrices that produce the same geometric result are connected by a path in the space of transformations.
- A shader that produces the same output for two different uniform configurations has a path between those configurations.

#### Exercises
1. In homotopy terms, what is a loop? Give an example from 3D transformations.
2. What does `ap(f, p)` mean when `f` is a rendering function and `p` is a proof that two scene states are equal?
3. Why is it important that equality is a type rather than a proposition outside the type system?

---

## Third Branch: Homotopy Levels (h-Levels)

### Truncation and Contractibility

Types in HoTT are classified by their **homotopy level** (h-level), which measures the complexity of their identity structure.

| h-level | Name               | Definition                                              | Example                          |
|---------|--------------------|---------------------------------------------------------|----------------------------------|
| -2      | Contractible       | Exactly one point, all paths trivial                    | Unit type `()`                   |
| -1      | Mere proposition   | At most one point; any two proofs of equality are equal | `boolean` used as a truth value  |
| 0       | Set                | Any two proofs of equality `a = b` are themselves equal | `string`, `number`               |
| 1       | Groupoid           | Paths have non-trivial but well-behaved higher paths    | Paths in a topological space     |
| n       | n-type / n-groupoid| Higher-dimensional path structure up to level n         | Homotopy groups                  |

- **Sets** (h-level 0) are the familiar world of ordinary programming: equality is decidable or at least unique up to proof.
- **Groupoids** (h-level 1) arise naturally in category theory: objects, morphisms, and equalities between morphisms.
- **Higher types** allow reasoning about equalities between equalities — crucial for advanced mathematics and for reasoning about equivalence of programs.

#### Examples
- The type `EntityId = string` is a set: two entity IDs are either equal or not, and any two proofs of that equality are the same.
- The type of rotation matrices modulo the group SO(3) is a groupoid: two rotations can be "equal" via a path (a continuous deformation).
- The universe of all types `Type` is not a set — it is a higher type, since types can be equivalent in multiple distinct ways.

#### Exercises
1. Is the type `boolean` a set, a mere proposition, or something else? Justify your answer.
2. Why does the type of all types `Type` not form a set in HoTT?
3. Give an example from this project where a type would naturally have h-level 1 (groupoid).

---

## Fourth Branch: The Univalence Axiom

### Equivalence of Types

Two types `A` and `B` are **equivalent** (written `A ≃ B`) if there is a function `f : A → B` with a quasi-inverse: a function `g : B → A` such that `g ∘ f ~ id_A` and `f ∘ g ~ id_B`.

The **Univalence Axiom** (Voevodsky, 2009) states:

> **`(A = B) ≃ (A ≃ B)`**

That is, **equality of types is equivalent to equivalence of types**. To give a proof that two types are equal is exactly the same as giving an equivalence between them.

This has profound consequences:
- Any property true of a type is true of any equivalent type.
- You can freely replace a type with an equivalent one without loss of information.
- Isomorphic mathematical structures are *identical*, not just *isomorphic*.

```typescript
// In TypeScript, we cannot state Univalence directly, but we can approximate:
// If A ≃ B (there's a bijection between them), then any generic function
// treating them as the same type is justified.

type Iso<A, B> = {
  to: (a: A) => B;
  from: (b: B) => A;
  // to ∘ from = identity on B
  // from ∘ to = identity on A
};

// Example: Vec2 represented as a tuple is equivalent to Vec2 as an object
type Vec2Tuple = [number, number];
type Vec2Object = { x: number; y: number };

const vec2Iso: Iso<Vec2Tuple, Vec2Object> = {
  to: ([x, y]) => ({ x, y }),
  from: ({ x, y }) => [x, y],
};
```

#### Why Univalence Matters for This Project

- **Representation independence**: if `Vec3` can be represented as `[number, number, number]` or as `{ x, y, z }`, univalence says these are genuinely interchangeable — not just informationally equivalent but *equal as types*.
- **Refactoring as proof**: refactoring code to use a different representation of the same concept is justified by an equivalence proof.
- **Transport**: any property proven about one representation automatically transfers to the other.

#### Exercises
1. Define an `Iso` between `Entity` represented as `{ id: string }` and `EntityId = string`. What does univalence say about them?
2. Why does univalence make the distinction between "isomorphic" and "equal" collapse for types?
3. Give an example where two representations in this project are equivalent and show the isomorphism.

---

## Fifth Branch: Higher Inductive Types (HITs)

### Types Defined by Generators and Relations

**Higher inductive types** extend ordinary inductive types by allowing not only point constructors (elements) but also **path constructors** (equalities between elements) and higher path constructors as part of the definition.

This allows you to define types whose identity structure is *prescribed* rather than derived.

#### Example 1: The Circle `S¹`

```
data S¹ where
  base : S¹                   -- a point
  loop : base = base          -- a path from base to itself (a loop)
```

The circle is the type freely generated by one point and one non-trivial loop. Its fundamental group is ℤ — the integers correspond to how many times you wind around the loop.

#### Example 2: Truncation

Given a type `A`, the **propositional truncation** `∥A∥` is the HIT that collapses all paths:

```
data ∥A∥ where
  | a |  : A → ∥A∥            -- embed a point
  squash : (x y : ∥A∥) → x = y -- all points are equal
```

`∥A∥` is inhabited if and only if `A` is inhabited, but it forgets *which* element — it is a mere proposition.

#### Example 3: Quotient Types

Given a type `A` and an equivalence relation `R`, the quotient `A / R` is the HIT:

```
data A/R where
  [_] : A → A/R
  eq  : (a b : A) → R a b → [ a ] = [ b ]
```

This is exactly how you define types of equivalence classes.

#### Applications in This Project

- **Gesture equivalence**: two sequences of hand positions that represent the same gesture are identified in the quotient type of gesture sequences modulo gesture-equivalence.
- **Model identity**: two meshes that are geometrically equivalent (up to isometry) can be identified in a quotient type.
- **State equivalence**: two universe states that produce the same rendered output are equivalent in the quotient by rendering-equivalence.

```typescript
// TypeScript approximation of quotient types using opaque types:
// We hide the raw representation and only expose operations that respect
// the equivalence relation.

type GestureClass = Readonly<{ _tag: "GestureClass"; canonical: string }>;

function makeGestureClass(raw: string): GestureClass {
  return { _tag: "GestureClass", canonical: normalize(raw) };
}

function normalize(raw: string): string {
  // Two gesture sequences normalize to the same string iff they are equivalent
  return raw.trim().toLowerCase();
}
```

#### Exercises
1. Define a HIT for the type of "directed graphs modulo isomorphism."
2. How would you use propositional truncation to express "there exists at least one model in the universe" as a mere proposition?
3. Describe the quotient type of universe states modulo rendering-equivalence. What would the path constructor look like?

---

## Sixth Branch: Dependent Types in TypeScript

### What TypeScript Supports

TypeScript provides several features that approximate dependent types:

| Concept                   | TypeScript Feature                                |
|---------------------------|---------------------------------------------------|
| Type-level functions      | Generic types, conditional types                  |
| Dependent pairs `Σ`       | Tagged unions, intersection types                 |
| Refinement types          | Template literal types, branded/opaque types      |
| Singleton types           | `as const`, literal types (`"pinch"`, `42`)       |
| Type-level computation    | Conditional types, mapped types, infer            |
| Finite enumerations       | Union of literal types                            |
| N-ary tuples              | Tuple types, variadic tuple types                 |

```typescript
// Singleton / literal type
type Pinch = "pinch";
type Grab  = "grab";
type GestureKind = Pinch | Grab;

// Refinement via branding (opaque type pattern)
type EntityId = string & { readonly _brand: "EntityId" };
function mkEntityId(s: string): EntityId { return s as EntityId; }

// Dependent-like tuple: a vector of exactly N numbers
type Vec<N extends number, Acc extends number[] = []> =
  Acc["length"] extends N ? Acc : Vec<N, [...Acc, number]>;

type Vec2 = Vec<2>; // [number, number]
type Vec3 = Vec<3>; // [number, number, number]
type Vec4 = Vec<4>; // [number, number, number, number]

// Dependent-like function: return type depends on input
type ZeroVec<N extends number> = Vec<N>;
// (The actual implementation would use a helper, but the type is exact)

// Sigma-like: a model guaranteed to have at least one vertex
type NonEmptyModel = {
  vertices: [Vec3, ...Vec3[]]; // at least one vertex
  connections: Array<[number, number]>;
};
```

### Limits of TypeScript's Type System

TypeScript's type system is deliberately not a full dependent type system:
- Types cannot depend on arbitrary runtime values (only on type-level representations).
- There is no built-in notion of proof or evidence term.
- Equality types (`a = b`) do not exist; equality is structural or referential.
- The type system is unsound in some edge cases (e.g., `any`, unsafe casts).

For full dependent types, consider: **Agda**, **Lean 4**, **Idris 2**, or **Coq/Rocq**.

#### Exercises
1. Define a branded type `Vec3` in TypeScript that prevents accidental confusion with a plain `[number, number, number]` tuple.
2. Use conditional types to write `Head<T>` that extracts the first element of a tuple type.
3. Why can't TypeScript express `Π (n : Nat), Vec n Float` exactly? What is the closest approximation?

---

## Seventh Branch: Connections to Category Theory

### Types and Categories

Every type theory gives rise to a category:
- **Objects**: types.
- **Morphisms**: functions between types.
- **Identity**: the `identity` function.
- **Composition**: function composition.

In dependent type theory, this category is richer:
- Morphisms can depend on values: `Π (x : A), B(x)`.
- There are **slice categories**: given `A`, the slice category over `A` has objects `Σ (x : A), B(x)`.
- **Fibrations** (dependent types) are the categorical analog of `Π` and `Σ`.

### The (∞,1)-Category of Types

In HoTT, the category of types is not an ordinary category but an **∞-groupoid** (or (∞,1)-category):
- Objects: types.
- 1-morphisms: functions `A → B`.
- 2-morphisms: homotopies between functions `(f g : A → B) → (f ~ g)`.
- 3-morphisms: homotopies between homotopies.
- And so on, to all dimensions.

This is the mathematical structure that unifies homotopy theory, category theory, and type theory.

### Functors as Type Constructors

A **functor** in this context is a type constructor `F` together with a mapping:
```
fmap : (A → B) → F A → F B
```
preserving identity and composition. In TypeScript:
```typescript
// Functor for arrays
const arrayFunctor = {
  fmap: <A, B>(f: (a: A) => B) => (fa: A[]): B[] => fa.map(f),
};

// Functor for Option/Maybe
type Option<A> = { tag: "Some"; value: A } | { tag: "None" };
const optionFunctor = {
  fmap: <A, B>(f: (a: A) => B) => (fa: Option<A>): Option<B> =>
    fa.tag === "Some" ? { tag: "Some", value: f(fa.value) } : { tag: "None" },
};
```

### Natural Transformations as Polymorphic Functions

A **natural transformation** `η : F → G` between functors is a polymorphic function:
```typescript
type NatTrans<F, G> = <A>(fa: F) => G; // simplified
// More precisely: for every A, a function η_A : F(A) → G(A),
// such that for every f : A → B, η_B ∘ F(f) = G(f) ∘ η_A
```

In practice, any parametrically polymorphic function in TypeScript is automatically a natural transformation (by parametricity).

#### Exercises
1. Show that `Array.prototype.map` makes `Array` a functor.
2. Define a natural transformation from `Option<A>` to `A[]`.
3. In categorical terms, what is the `Universe` type in this project? What are its morphisms?

---

## Advanced Node: Fiber Bundles and Dependent Types

A **fiber bundle** is a structure `(E, B, π)` where:
- `B` is the base space.
- `E` is the total space.
- `π : E → B` is the projection.
- For each `b : B`, the **fiber** `π⁻¹(b)` is the type of things "over" `b`.

In dependent type theory:
- `B` is a type (e.g., `EntityId`).
- The fiber over `b` is `Component(b)` (the component data for a specific entity).
- The total space `Σ (id : EntityId), Component(id)` is the bundle.

This is exactly the **entity-component system** pattern, expressed in the language of fiber bundles.

```typescript
// The fiber bundle pattern in this project:
type ComponentMap<Id extends string> = {
  [K in Id]: ComponentData; // fiber over each entity id
};

// Total space:
type EntityWithComponent = {
  id: EntityId;
  component: ComponentData;
};

// Projection:
const project = (e: EntityWithComponent): EntityId => e.id;
```

---

## Creative Node: HoTT in Practice

### Why HoTT Matters for Immersive Experience Design

- **Representation independence**: the choice of data structure (tuple vs. object, row vs. column vector) should not matter for correctness — univalence formalizes this.
- **Proof-relevant equality**: two gesture sequences that "mean the same thing" are connected by a path, and that path carries information about *how* they are equivalent.
- **Higher coherences**: when composing transformations, associativity and unit laws hold not just propositionally, but up to paths — and these paths satisfy their own higher laws.
- **Quotient types**: identifying equivalent states, gestures, or models without boilerplate equality logic.

### Connections to the Universe Model

The single `Universe` object in this project is the **total space** of a fibration over time:
- Each tick `t` is a point in time (the base).
- The universe state at tick `t` is the fiber over `t`.
- The application loop is a **section** of this bundle: a function that picks a universe state for each tick.
- Paths in the universe (equalities between states) correspond to **invariants** preserved across ticks.

---

## Glossary

| Term                     | Definition                                                                       |
|--------------------------|----------------------------------------------------------------------------------|
| **Dependent type**       | A type that depends on a value                                                   |
| **Π type**               | Dependent function type; generalizes `A → B`                                    |
| **Σ type**               | Dependent pair type; generalizes `A × B`                                        |
| **Identity type**        | The type of proofs that two terms are equal; written `a = b`                    |
| **Path**                 | A term of an identity type; a proof of equality                                 |
| **Homotopy**             | A path between paths; a 2-dimensional equality                                  |
| **h-level**              | The complexity of a type's identity structure (contractible, proposition, set…) |
| **Univalence**           | The axiom that equivalent types are equal: `(A = B) ≃ (A ≃ B)`                 |
| **Higher inductive type**| A type defined by both point and path constructors                              |
| **Fiber bundle**         | A family of types indexed by a base type; the dependent type `Σ (x : A), B(x)` |
| **∞-groupoid**           | A structure with objects, morphisms, and higher morphisms at all dimensions      |
| **Curry–Howard**         | The correspondence between types/proofs/programs and propositions/spaces         |

---

## Research Areas and Further Reading

- **Homotopy Type Theory** (The HoTT Book, 2013) — the foundational reference, freely available at [homotopytypetheory.org](https://homotopytypetheory.org/book/).
- **Cubical Type Theory** — a computational interpretation of univalence (Coquand et al., 2016).
- **Lean 4** — a proof assistant and programming language with dependent types.
- **Agda** — a dependently typed programming language and proof assistant.
- **Idris 2** — a dependently typed language designed for general-purpose programming.
- **Effect-TS / fp-ts** — functional programming in TypeScript, approximating categorical structure.
- **Voevodsky's Univalent Foundations** — the mathematical program that gave rise to HoTT.
- **∞-categories** (Lurie, *Higher Topos Theory*) — the categorical foundations of HoTT.

---

## Solutions to Exercises

### Curry–Howard
1. `Π (m : Model), m.vertices.length > 0` (or in TypeScript: `NonEmptyModel`).
2. A term of `A × B` proves both `A` and `B` simultaneously; it is a conjunction.
3. The type `A → Never` (also called `¬A`); it states that `A` leads to absurdity.

### Dependent Types
1. `Π (n : Nat), Vec<n, Vec3>` — a function from a count to an array of exactly that many `Vec3` values.
2. `Σ (id : string), id.length > 0` — a non-empty string entity ID.
3. `Σ (x : A), B(x)` pairs a value with evidence; `A × B` pairs two independent values with no dependency.

### Identity Types
1. A loop is a path `base = base` in the space; e.g., a rotation by 360° returns to the identity.
2. `ap(render, p)` shows that if two scene states are equal, their rendered outputs are equal.
3. Equality as a type allows it to carry information (the path), enables proof transport, and supports higher equalities.

### Homotopy Levels
1. `boolean` is a set (h-level 0): `true ≠ false`, and any two proofs of `true = true` are the same.
2. `Type` is not a set because two types can be equivalent in multiple distinct ways (different bijections).
3. The type of paths between two transformation matrices is h-level 1 (groupoid), since paths between paths capture homotopies.

### Univalence
1. `Iso<{id: string}, string>` with `to = e => e.id` and `from = s => {id: s}`; univalence says these types are interchangeable.
2. Univalence makes every property invariant under equivalence, so "isomorphic" structures have identical properties.
3. `Vec3` as `[number, number, number]` ≃ `Vec3` as `{x, y, z}` via the obvious `to/from` pair.

### Higher Inductive Types
1. Directed graphs modulo isomorphism: point constructor for each graph, path constructor for each isomorphism.
2. `∥ Σ (m : Model), m ∈ universe.models ∥` — the truncation forgets which model, retaining only existence.
3. Path constructor: `renderEquiv : (s t : UniverseState) → render(s) = render(t) → [s] = [t]`.

### Dependent Types in TypeScript
1. `type Vec3 = [number, number, number] & { readonly _brand: "Vec3" }`.
2. `type Head<T extends [unknown, ...unknown[]]> = T extends [infer H, ...unknown[]] ? H : never`.
3. TypeScript's type system is not fully dependent: `N` in `Vec<N>` must be a type-level literal, not an arbitrary runtime value.

### Category Theory
1. `Array`: `fmap(id) = id` and `fmap(f ∘ g) = fmap(f) ∘ fmap(g)`, satisfied by `Array.prototype.map`.
2. `η<A> : Option<A> → A[] = (opt) => opt.tag === "Some" ? [opt.value] : []`.
3. `Universe` is an object in the category of types; its morphisms are tick functions `Universe → Universe`.
