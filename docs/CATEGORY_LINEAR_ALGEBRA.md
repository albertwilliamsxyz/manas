# Category Theory and Linear Algebra

## Vision and Purpose

This document explores linear algebra through the lens of category theory, bridging the conceptual tree described in `LINEAR_ALGEBRA.md` with the categorical architecture of this project. The goal is to reveal the deep structure underlying vectors, matrices, and transformations — not as ad-hoc tools, but as objects and morphisms in a well-defined mathematical universe.

Category theory provides the language to reason about structure-preserving maps, composition, and abstraction at any level of generality. By understanding linear algebra categorically, you gain a framework that scales from 2D transformations to neural networks, quantum mechanics, and beyond.

---

## Visión y Propósito

Este documento explora el álgebra lineal a través de la teoría de categorías, conectando el árbol conceptual descrito en `LINEAR_ALGEBRA.md` con la arquitectura categórica de este proyecto. El objetivo es revelar la estructura profunda detrás de vectores, matrices y transformaciones, no como herramientas ad-hoc, sino como objetos y morfismos en un universo matemático bien definido.

---

## Part I: Categories — The Skeleton

### What is a Category?

A **category** C consists of:

1. A collection of **objects** (denoted `|C|`)
2. For every pair of objects A, B, a collection of **morphisms** (arrows) `C(A, B)` — often written `f: A → B`
3. A **composition** law: given `f: A → B` and `g: B → C`, there is `g ∘ f: A → C`
4. An **identity morphism** `id_A: A → A` for every object A

These must satisfy:

- **Associativity**: `h ∘ (g ∘ f) = (h ∘ g) ∘ f`
- **Identity laws**: `id_B ∘ f = f` and `f ∘ id_A = f`

Think of a category as a directed graph with composition rules — exactly the kind of structure used in the transformation pipelines of this application.

#### Examples of Categories

| Category | Objects | Morphisms |
|----------|---------|-----------|
| **Set** | Sets | Functions |
| **Vect_k** | Vector spaces over field k | Linear maps |
| **Grp** | Groups | Group homomorphisms |
| **Type** (TypeScript/Haskell) | Types | Pure functions |
| **Mat_k** | Natural numbers n | n×m matrices over k |

The last two are directly relevant to this project: types and functions form a category, and matrices form a category where composition is matrix multiplication.

---

## Part II: The Category Vect

### Vector Spaces as Objects

The category **Vect_k** (or simply **Vect** when the field k is understood) has:

- **Objects**: Vector spaces over a field k (e.g., ℝ for real numbers)
- **Morphisms**: Linear maps (linear transformations) between vector spaces
- **Composition**: Function composition of linear maps
- **Identity**: The identity transformation `id_V: V → V`

This is the categorical home of all linear algebra.

### Linear Maps as Morphisms

A **linear map** `f: V → W` is a function between vector spaces that preserves the vector space structure:

```
f(u + v) = f(u) + f(v)          (additivity)
f(c · v) = c · f(v)             (scalar homogeneity)
```

Linear maps are exactly the morphisms in Vect. They are the structure-preserving maps — the arrows of the category.

In 3D graphics, every transformation matrix (rotation, scaling, translation via homogeneous coordinates) represents a linear map. Composing transformations corresponds to composing morphisms in Vect.

#### Key Morphisms in the Project

```typescript
// A linear map from ℝ³ to ℝ³ represented as a 4×4 matrix (homogeneous coordinates)
type LinearMap = Float32Array  // column-major 4×4 matrix

// Composition of morphisms = matrix multiplication
const compose = (f: LinearMap, g: LinearMap): LinearMap => multiplyMat4(f, g)

// Identity morphism = identity matrix
const identity: LinearMap = new Float32Array([
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1
])
```

### The Category Mat

There is a related category **Mat_k** where:

- **Objects**: Natural numbers 0, 1, 2, 3, ...
- **Morphisms**: An m×n matrix over k is a morphism from n to m
- **Composition**: Matrix multiplication

This gives a concrete matrix calculus for working with Vect. A vector space ℝⁿ corresponds to the object n in Mat.

#### Exercises

1. Show that the composition of two linear maps is itself linear.
2. In Mat, what is the identity morphism for object 4 (the 4×4 case used in this project)?
3. Write the TypeScript type signature for a function that composes two 4×4 matrices.
4. Prove that matrix multiplication is associative (the categorical associativity law).

---

## Part III: Functors — Structure-Preserving Maps Between Categories

### What is a Functor?

A **functor** `F: C → D` maps:

- Every object `A` in C to an object `F(A)` in D
- Every morphism `f: A → B` in C to a morphism `F(f): F(A) → F(B)` in D

Such that:

- `F(id_A) = id_{F(A)}`  (preserves identities)
- `F(g ∘ f) = F(g) ∘ F(f)` (preserves composition)

Functors are the structure-preserving maps between categories — they are morphisms in the category of categories (**Cat**).

### Functors in Linear Algebra

#### Dual Space Functor

The **dual space** of a vector space V is `V* = Hom(V, k)` — the space of all linear functionals on V. This defines a functor:

```
(-)* : Vect_k → Vect_k
```

- Objects: `V ↦ V*`
- Morphisms: For `f: V → W`, the dual map `f*: W* → V*` is defined by `f*(φ) = φ ∘ f`

Note: the dual functor reverses arrows — it is a **contravariant functor**.

#### Tensor Product Functor

For a fixed vector space W, the functor `(- ⊗ W): Vect → Vect` maps:

- `V ↦ V ⊗ W`
- `f ↦ f ⊗ id_W`

In graphics, this corresponds to extending scalars or combining coordinate systems.

#### Forgetful Functor

There is a functor `U: Vect_k → Set` that "forgets" the vector space structure, remembering only the underlying set of vectors. This is an example of how structure can be systematically forgotten (and sometimes recovered via adjunctions).

### Functors in This Project

The layers of the application can be understood as functors:

```
Nuclear Layer ──(render functor)──▶ Graphics Layer
     │                                    │
  (state)                            (WebGL state)
```

Each application "tick" applies a sequence of functors, transforming the abstract nuclear state into concrete graphics state:

```typescript
// Conceptual: a functor from NuclearState to GraphicsState
type RenderFunctor = (nuclearState: NuclearState) => GraphicsState

// The projection matrix computation is a linear map in Vect
type ProjectionFunctor = (viewParams: ViewParameters) => Float32Array
```

#### Exercises

1. Is the identity function on Vect a functor? What does it send objects and morphisms to?
2. Define a functor from Mat to Vect that sends n to ℝⁿ.
3. Show that composing two functors yields a functor.
4. In what sense is the "graphics layer" of this application a functor from the nuclear state category?

---

## Part IV: Natural Transformations — Morphisms Between Functors

### What is a Natural Transformation?

Given two functors `F, G: C → D`, a **natural transformation** `η: F ⇒ G` assigns to each object A in C a morphism `η_A: F(A) → G(A)` in D, such that for every morphism `f: A → B` in C:

```
η_B ∘ F(f) = G(f) ∘ η_A
```

This **naturality square** commutes:

```
F(A) ──F(f)──▶ F(B)
 │                │
η_A             η_B
 │                │
 ▼                ▼
G(A) ──G(f)──▶ G(B)
```

Natural transformations are the "morphisms between functors" — they capture the notion of a systematic, coherent family of maps.

### Natural Transformations in Linear Algebra

#### Evaluation Map

For the identity functor and the double dual functor `V ↦ V**`, there is a natural transformation:

```
ev: Id ⇒ (-)**
ev_V(v)(φ) = φ(v)    for v ∈ V, φ ∈ V*
```

When V is finite-dimensional, `ev_V` is an isomorphism — V is naturally isomorphic to its double dual. This is the categorical statement of "there is no arbitrary choice of basis needed."

#### Determinant

The determinant `det: GL_n(k) → k*` is a natural transformation from the general linear group functor to the multiplicative group of the field. It satisfies `det(A·B) = det(A)·det(B)`, which is exactly the naturality condition for group homomorphisms.

#### Trace

The trace `tr: End(V) → k` is a natural transformation from the endomorphism functor to the constant-k functor. Its key property `tr(AB) = tr(BA)` expresses a form of naturality.

### Natural Transformations in This Project

Shader uniform updates can be understood as natural transformations. When the model transformation changes, the view and projection updates must commute with the rendering pipeline in a coherent way:

```typescript
// Natural transformation: for each entity, coherently update its transformation
type TransformUpdate = <A extends EntityId>(entity: A) => ModelMatrix
```

The naturality condition ensures that updating a transformation and then rendering gives the same result as rendering and then applying the corresponding visual transformation.

#### Exercises

1. Verify that `ev_V` defined above satisfies the naturality square.
2. Show that `tr(AB) = tr(BA)` follows from the naturality of the trace.
3. In the project's architecture, identify a family of maps that forms a natural transformation between layers.
4. What would it mean for a shader update function to *fail* naturality?

---

## Part V: Adjunctions — Universal Constructions

### What is an Adjunction?

An **adjunction** `F ⊣ G` between functors `F: C → D` and `G: D → C` consists of a natural bijection:

```
D(F(A), B) ≅ C(A, G(B))
```

for all objects A in C and B in D. F is called the **left adjoint** and G the **right adjoint**.

Adjunctions capture "universal constructions" — they explain why certain constructions are canonical.

### Adjunctions in Linear Algebra

#### Free Vector Space ⊣ Forgetful Functor

The **free vector space** functor `Free: Set → Vect` sends a set S to the vector space with S as a basis (formal linear combinations of elements of S). It is left adjoint to the forgetful functor `U: Vect → Set`:

```
Vect(Free(S), V) ≅ Set(S, U(V))
```

A linear map from Free(S) is completely determined by where it sends the basis elements — which is just a function from S to V. This is the categorical statement of the "universal property of the free vector space."

**Application in this project**: Loading a 3D model (a set of vertices) and treating them as generators of a free vector space corresponds to this adjunction. The linear maps (transformations) applied to the model are determined by where the basis vertices go.

#### Tensor ⊣ Hom (Currying)

For vector spaces, there is an adjunction:

```
Vect(V ⊗ W, U) ≅ Vect(V, Hom(W, U))
```

This is the linear algebra version of function currying. A bilinear map `V × W → U` corresponds to a linear map `V → Hom(W, U)`. In shader programming, this corresponds to how vertex and fragment shaders interact with uniform matrices.

#### Exercises

1. Verify that a linear map from Free({e₁, e₂, e₃}) to ℝ² is the same as a 2×3 matrix.
2. Explain the tensor-hom adjunction using the example of a bilinear form.
3. How does the free vector space adjunction appear when uploading vertex data to a GPU buffer?

---

## Part VI: Monoidal Categories — Tensor Products

### Monoidal Structure on Vect

The category **Vect** is a **monoidal category** with:

- **Tensor product**: `V ⊗ W` (the monoidal product)
- **Unit object**: k (the field itself, with dim 1)
- **Associator**: `(V ⊗ W) ⊗ U ≅ V ⊗ (W ⊗ U)` (natural isomorphism)
- **Unitors**: `k ⊗ V ≅ V ≅ V ⊗ k`

The monoidal structure satisfies the **pentagon** and **triangle** coherence equations, ensuring that all ways of reassociating are consistent.

### Symmetric Monoidal Structure

Vect is also **symmetric**: there is a natural isomorphism `σ_{V,W}: V ⊗ W ≅ W ⊗ V`. This corresponds to the fact that tensor product of vector spaces doesn't depend on the order (unlike matrix multiplication, which is not commutative).

### Relevance to Graphics

Matrix multiplication implements composition in Vect. The non-commutativity of matrix multiplication reflects the fact that composing linear maps is ordered (rotations don't commute). The tensor product, however, is symmetric — combining coordinate systems does not depend on order.

In GLSL shaders:

```glsl
// Composition (non-commutative): order matters
gl_Position = u_projection * u_view * u_model * vec4(a_position, 1.0);

// The above expands as: proj ∘ view ∘ model applied to position
// Changing the order gives a different result
```

#### Exercises

1. What is `ℝ² ⊗ ℝ³` as a vector space? What is its dimension?
2. Show that `σ_{V,W} ∘ σ_{W,V} = id_{V⊗W}`.
3. How does the pentagon coherence equation relate to the associativity of matrix multiplication?

---

## Part VII: Linear Algebra Through the Yoneda Lens

### The Yoneda Lemma

The **Yoneda Lemma** is one of the most fundamental results in category theory. For a category C and a functor `F: C → Set`, it states:

```
Nat(C(A, -), F) ≅ F(A)
```

naturally in A. In words: natural transformations from the representable functor `C(A, -)` to F are in bijection with elements of `F(A)`.

### Application to Linear Algebra

In Vect, the Yoneda lemma applied to the representable functor `Vect(k, -)` (linear functionals, i.e., the dual space construction) gives:

```
Nat(Vect(k, -), F) ≅ F(k)
```

A natural transformation from the "scalar functor" to any other functor F is just an element of `F(k)`. This explains why linear functionals are the "atoms" of linear algebra — everything reduces to the behavior on the field itself.

### The Embedding Principle

The Yoneda embedding `よ: C^op → Set^C` sends:

```
A ↦ C(-, A)
```

This is fully faithful — two objects are isomorphic if and only if their representable functors are naturally isomorphic. Applied to linear algebra: two vector spaces are isomorphic (as objects in Vect) if and only if they have the same dimension. The representable functor captures the entire structure.

**Design principle for this project**: By representing each entity as a morphism in the category (via its transformation matrices), the Yoneda perspective tells us that the entity is fully determined by how it relates to all other entities — its position in the "web" of transformations. This is the categorical foundation for why transformation matrices fully describe a 3D entity.

---

## Part VIII: Connecting to This Project's Architecture

### The Universe as a Category

The `Universe` object in this project is not just a data structure — it is an **initial object** or **terminal object** (depending on perspective) in a category of application states:

```haskell
-- From DESIGN.md
data Universe = Universe {
  models   :: [Model],
  entities :: [Entity]
}
```

Viewed categorically:
- **Objects**: All possible `Universe` states
- **Morphisms**: Pure functions `Universe → Universe` (state transitions)
- **Identity**: `id: Universe → Universe` (no-op tick)
- **Composition**: Sequential application of state transitions

### Transformations as Morphisms

Every 3D transformation in the graphics layer is a morphism in Vect:

| Transformation | Linear Map | Matrix |
|---------------|-----------|--------|
| Scaling | `S: ℝ³ → ℝ³` | diagonal matrix |
| Rotation around X | `Rx: ℝ³ → ℝ³` | rotation matrix |
| Rotation around Y | `Ry: ℝ³ → ℝ³` | rotation matrix |
| Rotation around Z | `Rz: ℝ³ → ℝ³` | rotation matrix |
| Translation (homogeneous) | `T: ℝ⁴ → ℝ⁴` | affine matrix |
| Projection | `P: ℝ⁴ → ℝ⁴` | projection matrix |

The composition `P ∘ V ∘ M` (projection × view × model) is categorical composition in Mat.

### Actions as Coproducts

From `DESIGN.md`:

```haskell
data Action = AddModel Model | AddEntity Entity | MoveVertex Int (Scalar, Scalar, Scalar) Int
```

This is a **coproduct** (sum type) in the category of types. The function `applyAction: Action × Universe → Universe` is a morphism that dispatches on the coproduct. Categorically, this is the universal property of coproducts: a morphism out of a coproduct is a family of morphisms, one per summand.

### Lenses as Natural Transformations

The `monocle-ts` library provides **lenses** — these are natural transformations in the category of functors. A lens `Lens S A` is equivalent to a pair of morphisms:

```typescript
get: S → A
set: A × S → S
```

satisfying coherence laws. In categorical terms, a lens is a coalgebra for the store comonad. Lenses allow updating nested state (e.g., a specific entity's position in the Universe) without violating the functional purity of state transitions.

---

## Part IX: Summary — The Categorical Map of Linear Algebra

```
Category Theory Concept   │  Linear Algebra Realization      │  Project Application
──────────────────────────┼──────────────────────────────────┼──────────────────────────
Object                    │  Vector space ℝⁿ                 │  Vertex buffer, shader uniform
Morphism                  │  Linear map, matrix              │  Transformation matrix (model/view/projection)
Composition               │  Matrix multiplication           │  M_total = T × Rz × Ry × Rx × S
Identity                  │  Identity matrix I               │  IDENTITY_MATRIX constant
Functor                   │  Dual space, tensor, forgetful   │  Render pipeline (nuclear → graphics)
Natural transformation    │  Evaluation, determinant, trace  │  Coherent shader uniform updates
Adjunction                │  Free ⊣ Forgetful, Tensor ⊣ Hom │  Vertex upload, shader currying
Monoidal product          │  Tensor product V ⊗ W            │  Combined coordinate systems
Yoneda lemma              │  Representable functors           │  Entities fully described by their morphisms
Coproduct (sum type)      │  Direct sum V ⊕ W                │  Action type, gesture state machine
Product                   │  Direct product V × W            │  Paired state (left hand, right hand)
```

---

## Part X: Exercises — Synthesis

1. **Category verification**: Show that Vect_ℝ with linear maps as morphisms satisfies all category axioms.
2. **Functor construction**: Define a functor from the category of 3D scenes (objects = scenes, morphisms = transformations) to Vect_ℝ that sends each scene to its vertex buffer as a vector space.
3. **Natural transformation**: Show that the "apply view matrix" operation is natural with respect to scene transformations.
4. **Adjunction application**: Explain how the free vector space adjunction underlies the design decision to store vertex data as flat arrays.
5. **Monoidal product**: In what sense is the combined transformation `M_total = T × Rz × Ry × Rx × S` a composite in a monoidal category?
6. **Yoneda in graphics**: Using the Yoneda lemma, explain why a 4×4 matrix completely determines a linear transformation of ℝ⁴.
7. **Architecture**: Map the nuclear, graphics, and gesture layers of this application to objects and functors in a category of categories.
8. **TypeScript types**: Show that TypeScript types and pure functions form a category, and identify at least three morphisms already present in `src/main.ts`.

---

## Solutions to Selected Exercises

### Category Verification (Exercise 1)

- **Closure**: The composition of two linear maps `f: U → V` and `g: V → W` is linear, so `g ∘ f: U → W` is in Vect.
- **Associativity**: `(h ∘ g) ∘ f = h ∘ (g ∘ f)` follows from associativity of function composition.
- **Identity**: `id_V(v) = v` is linear, and `f ∘ id_V = f = id_W ∘ f` for any `f: V → W`.

### Adjunction Application (Exercise 4)

Vertex data is stored as a flat `Float32Array` (a free module). Loading a model gives a set of basis vertices; any linear map from the model space is determined by where each vertex goes. This is the free vector space adjunction: `Vect(Free(Vertices), ℝ⁴) ≅ Set(Vertices, ℝ⁴)`. The GPU shader is exactly this linear map.

### TypeScript Morphisms (Exercise 8)

From `src/main.ts`:

```typescript
// f: HTMLCanvasElement → Option<HTMLCanvasElement>  (morphism in Type)
const getApplicationCanvas = (): O.Option<HTMLCanvasElement> => ...

// g: HTMLCanvasElement → Either<Error, WebGL2RenderingContext>  (morphism in Type)
const createGraphicLibraryContext = (canvas: HTMLCanvasElement): E.Either<Error, WebGL2RenderingContext> => ...

// h: WebGL2RenderingContext → Either<Error, WebGLShader>  (morphism in Type)
const createVertexShader = (gl: WebGL2RenderingContext): E.Either<Error, WebGLShader> => ...
```

The `pipe` function from `fp-ts` implements categorical composition, threading morphisms together:

```typescript
// Composition: canvas → vertexShader
pipe(
  createVertexShader(gl),
  E.chain((vertexShader) => initializeVertexShader(gl, vertexShader)),
  ...
)
```

---

## Further Reading

- **Mac Lane, S.** — *Categories for the Working Mathematician* (the foundational reference)
- **Riehl, E.** — *Category Theory in Context* (freely available online, excellent exposition)
- **Fong, B. & Spivak, D.** — *An Invitation to Applied Category Theory* (applied focus, connects to engineering)
- **Milewski, B.** — *Category Theory for Programmers* (Haskell/TypeScript perspective, connects to fp-ts)
- **Baez, J. & Stay, M.** — *Physics, Topology, Logic and Computation: A Rosetta Stone* (connections to quantum mechanics and linear algebra)
