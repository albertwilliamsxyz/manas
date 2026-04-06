---
name: Albert - Project Creator
description: Albert is building Manas, an immersive AR spatial instrument in PureScript + WebXR. Uses Neovim with session management and CodeCompanion. Works from macOS.
type: user
---

# Who I Am

Albert is the sole developer of Manas. Uses Neovim with session management and CodeCompanion plugin. Works on macOS. Writes PureScript (~90%) with JavaScript FFI for WebXR/WebGL2 — comfortable with functional programming, typed FFI, low-level graphics APIs, and category theory as working architecture (not academic decoration).

The broader vision: exploring UIs of the future — leveraging technology and VR as scaffolding to enhance and accelerate thought, offloading cognition into spatial/visual environments so the mind can operate at a higher level. Manas is the first concrete manifestation of this research program.

Prior work includes a working WebGPU engine in the browser and a blockchain transaction graph visualizer, giving practical intuition for the mathematical machinery underlying the current projects.

# Manas — The Project

A WebXR hand-tracking AR engine written in PureScript with WebGL2 and WebXR, tested in Meta Quest headsets. Browser-based (no app store). Not a tech demo — a cognitive extension and artisanal craft. The vision: a spatial mathematical instrument where anything definable can be manifested, manipulated, and composed. A "programming language for thought."

## Architecture — Completed

- Full type system: `Topology`, `GeometryId`, `Geometry`, `GPUHandle`, `Transform`, `SceneObject`, `WorldState`, `HandInput`, `InteractionMode`, `HandState`, `InteractionResult`, `Handedness`
- Separation of domain geometry from GPU resources
- `Map` over `Array` for deletable scene objects with `SceneObjectId` keys
- `nextObjectId` as auto-increment for ID generation
- Single `Ref WorldState` for mutable state
- Full interaction system ADT (`InteractionMode`: `Observing`, `OneHandManipulate`, `TwoHandManipulate`)
- `updateInteraction` as the central interaction function — pure, handles all mode transitions
- Two-hand manipulation via HandleBar metaphor
- Ray-triangle intersection (Möller-Trumbore algorithm)
- Proximity-based collision detection via `findNearestObject`
- Linear algebra primitive library in FFI (`sub3`, `translationMatrix4x4`, `multiplyMatrix4x4`, `get3DDistanceFromMatrix`, `getTranslationFromMatrix`, `getScaleFromMatrix`)
- `ExceptT String Effect` for error handling in some paths, `Effect` in others (inconsistency identified for future cleanup)

## Architecture — Identified Problems & Next Steps

- Four identified coupling problems with proposed refactors: `RenderCommand` as pure data, opaque `Transform`, parametrized spawn by geometry type, extracted `setupVAO`
- `Transform` currently speaks the GPU's language (Float32Array matrices), not the domain's — the representation leaked upward. Correct frontier: domain pure types → conversion → Float32Array at render time. This makes WebGL and WebXR interchangeable as plugins
- Collision detection needs `isPointInsideMesh` (ray casting + counting odd intersections) to replace the current center-distance heuristic
- Quaternions needed when interpolating rotations smoothly over time
- Study the interpreter pattern via `purescript-run`
- Review two-hand manipulation mathematics on paper
- Error handling policy needs crystallization: which errors are recoverable vs fatal, visible in types

## Development Philosophy

- Centralizar primero, abstraer solo cuando el patrón aparece 3-4 veces, nunca abstraer de más
- Discover architecture by layers — naming first, crystallization after
- The monolith is where patterns become visible before being abstracted
- Every concept internalized doesn't add — it multiplies (myelination metaphor)
- Essential complexity (from the problem) vs accidental complexity (from tools/representations): asymmetric acceleration comes from attacking the accidental
- Emergent systems aren't magic — they're consequences of modeling the correct relationships
- The program has dual nature: as algebra (data, geometries, scene graph — finite, foldable) and as coalgebra (the loop, time, interaction — potentially infinite, unfoldable). `tick` lives at the frontier between them

# Buddhi — Secondary Project

Market regime detection system for crypto assets. The "discriminating intelligence" layer. Architecture targets a universal, asset-agnostic trading system with volatility-normalized signals, regime detection across trend/volatility/sentiment axes, Kelly-fractional position sizing, and multi-type exit management.

# How I Learn

- Through dialogue and exposition, not documentation
- Thinks in structures and isomorphisms — connecting graph-matrix duality, the holographic principle, and category theory to working code
- Deep in PureScript's type system: ADTs, type classes, FFI nuances, rank-N polymorphism, the kind system, row polymorphism, record structural typing
- Has studied: F-algebras, F-coalgebras, catamorphisms (fold), anamorphisms (unfold), hylomorphisms, Curry-Howard correspondence, combinatory logic (S, K, I), eta-reduction, point-free style as information reduction
- Bilingual: comfortable in English and Spanish, conversations flow between both

# Collaboration Rules — Non-Negotiable

1. **Minimal scope**: each function should know as little context as possible
2. **Named types**: always prefer named types over anonymous record types in function signatures
3. **I design signatures**: I design function signatures before implementation. Present options, don't decide for me
4. **Review before implementing**: I want to review and approve each code snippet before it goes into the codebase
5. **Intent over mechanics**: naming describes the relationship between input and output, not the internal steps. `uploadGeometry` over `getGPUHandleFromGeometry`. `interpretTransform` over `composeModelMatrix`
6. **Stay concrete**: do not speculate beyond the question asked. Do not drift into unrelated projects. If I ask about Manas, don't bring up Buddhi
7. **Honesty signal**: when I call something "beautiful," that's a reliable indicator the architectural decision is correct
8. **No vibecoding**: I insist on understanding every concept before moving forward. Explain the why, not just the what
9. **Extended responses welcome**: when exploring concepts, give thorough explanations — I learn through depth, not breadth

# Naming Vocabulary — From First Principles

These are the naming patterns we established. Use them consistently:

- `toX` — conversion preserving identity, same concept different form (morphism preserving information)
- `fromX` — inverse of `toX`; when both exist for the same type pair, they describe an isomorphism
- `interpretX` — crossing a conceptual frontier, translating between languages/abstraction levels
- `makeX` — construction from components
- `withX` — transformation preserving context
- `getX` / `xOf` — extraction (prefer `xOf` for declarative style)
- The name should read as a sentence in context: `cubeGPUHandle <- uploadGeometry webGL2Context positionLocation cubeGeometry`

# Code Quality Principles

- **Totality**: a total function is defined for all possible input values. A partial function has a name that lies. `fromMaybe 0.0 (vertices !! offset)` is a silent lie
- **Auditing totality and auditing names is the same act**: asking whether the function is honest about what it does
- **Types as implicit declarations**: a well-constructed type is already documentation, specification, and restriction. Don't comment what the type already says
- **Domain purity frontier**: domain pure types → conversion at the boundary → GPU representation. Pay the conversion cost once, at render time, not before
