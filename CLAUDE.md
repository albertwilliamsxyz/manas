# Manas

A spatial mathematical instrument — a WebXR hand-tracking AR engine in PureScript with WebGL2, browser-based, tested on Meta Quest.

## Stack

- PureScript with JavaScript FFI
- WebGL2 for rendering
- WebXR for immersive AR and hand tracking
- Spago (build tool), esbuild (bundler)

## Commands

```bash
spago build                # compile PureScript → output/
npm run build              # compile + bundle → dist/main.js
npm run serve:https        # serve over HTTPS (required for WebXR)
```

WebXR requires HTTPS. Use `serve:https` for testing on headset.

## Project structure

```
src/
  Main.purs            # Entry point, all not-yet-crystallized logic
  WebGL2.purs + .js    # WebGL2 FFI binding (flat, 1:1 with JS API)
  WebXR.purs + .js     # WebXR FFI binding (Impl/wrapper pattern for Promise→Aff)
  ForeignUtils.purs + .js  # Mixed FFI: typed arrays, vec3 ops, mat4 ops, spatial ops
                           # (to be separated — see TODO.md)
```

Main.purs is the workspace where functionality lives before being crystallized into abstractions. The modules outside Main are the first crystallizations.

## Architecture principles

### Progressive crystallization

Abstractions emerge through layers, never top-down:
1. All new functionality starts in Main
2. Comment potential patterns to mark them
3. Update naming to reflect emerging concepts
4. Define types when the concept is clear
5. Extract functions when a pattern repeats 3-4 times
6. Extract modules when a group of functions has clear identity

### Parse, don't validate

Validate at system boundaries (FFI, XR frames, WebGL). Construct domain types at that boundary. After construction, the type carries the guarantee — internal operations are total with simple signatures. Never add validation inside pure operations on domain types.

### Dependencies flow downward

Layers depend only on layers below them, never above. Foundational layers (linear algebra) are accessible by all. Pipeline layers each consume one type and produce another.

### Type honesty

Types should reflect what functions actually accept and return. `sub :: Vec3 -> Vec3 -> Vec3`, not `Float32Array -> Float32Array -> Float32Array`. When the type is honest, the name simplifies — the name stops compensating for what the type doesn't say.

### Naming vocabulary

- `toX` / `fromX` — conversion preserving identity (isomorphism when both exist)
- `interpretX` — crossing a conceptual frontier between abstraction levels
- `makeX` — construction from components
- `withX` — transformation preserving context
- `xOf` — extraction (prefer over `getX`)
- Names read as sentences in context: `cubeGPUHandle <- uploadGeometry webGL2Context positionLocation cubeGeometry`
- Intent over mechanics: naming describes input→output relationship, not internal steps

### Module structure for FFI

FFI modules have two sub-layers:
1. Raw FFI binding — flat, 1:1 with JS API
2. PureScript-idiomatic layer — typed, Maybe instead of Nullable, Aff instead of Promise

## Collaboration rules

1. Minimal scope: each function knows as little context as possible
2. Named types: always prefer named types over anonymous records in signatures
3. I design signatures: present options, don't decide
4. Review before implementing: I approve each code snippet before it enters the codebase
5. No vibecoding: explain the why, not just the what
6. Stay concrete: don't speculate beyond the question asked
7. Extended responses welcome when exploring concepts

## Current state

Working: hand tracking (25 joints/hand), pinch gestures, cube spawning, one-hand grab, two-hand manipulate (translate + scale + rotate). See TODO.md for planned work.
