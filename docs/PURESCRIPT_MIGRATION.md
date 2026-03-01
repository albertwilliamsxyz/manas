# PureScript Migration

This document describes the migration of the Manas codebase from TypeScript (with fp-ts) to PureScript.

---

## Motivation

The original codebase used TypeScript with the `fp-ts` library to bring functional programming patterns (Option, Either, pipe) into the application. PureScript is a strongly-typed, purely functional programming language that compiles to JavaScript and provides these patterns natively, making it a natural progression for the project's functional and categorical architecture.

Key benefits of the migration:

- **Native algebraic data types**: PureScript has sum types, product types, and pattern matching built into the language rather than relying on library encodings.
- **Purity by default**: All side effects are tracked in the type system via the `Effect` monad, aligning with the project's goal of composable, predictable state transformations.
- **Stronger type inference**: PureScript's Hindley-Milner type system provides more powerful inference than TypeScript's structural typing.
- **Row polymorphism**: PureScript's record system supports row polymorphism, enabling flexible and extensible record types for entities, uniforms, and configuration.
- **FFI for browser APIs**: PureScript's Foreign Function Interface allows direct interop with WebGL2 and WebXR APIs while maintaining type safety at the boundary.

---

## Project Structure

### Before (TypeScript)

```
src/
  main.ts          -- All application logic in a single file
  main.old.js      -- Legacy JavaScript version
  main.copy.js     -- Alternative JavaScript version
package.json       -- fp-ts, lodash, monocle-ts, uuid dependencies
tsconfig.json      -- TypeScript configuration
```

### After (PureScript)

```
src/
  Main.purs              -- Application entry point and XR session logic
  Main.js                -- FFI: hand input processing, view rendering, DOM setup
  Manas/
    Constants.purs       -- Domain constants (joints, cube vertices, identity matrix)
    Shaders.purs         -- GLSL shader source strings
    Graphics.purs        -- WebGL2 type declarations and FFI signatures
    Graphics.js          -- FFI: WebGL2 API bindings
    WebXR.purs           -- WebXR type declarations and FFI signatures
    WebXR.js             -- FFI: WebXR API bindings
  main.ts                -- Original TypeScript source (retained for reference)
  main.old.js            -- Legacy JavaScript version (retained for reference)
  main.copy.js           -- Alternative JavaScript version (retained for reference)
spago.yaml             -- PureScript package manager configuration
package.json           -- Simplified (no fp-ts/lodash/monocle-ts/uuid)
```

---

## Module Overview

### `Manas.Constants`

Pure data module containing all domain constants:

- `baseNumberOfDimensions`, `numberOfJointsPerHand`, `numberOfHandJointDimensions`
- `handSkeletonByJointIndices` — index pairs defining the hand skeleton topology
- Named joint index constants (`wrist`, `thumbTip`, `indexFingerTip`, etc.)
- `cubeVertices` — the 36-vertex cube geometry
- `lookupJointIndex` — pattern-matched function mapping joint name strings to indices

### `Manas.Shaders`

Contains the GLSL shader source strings:

- `vertexShaderSource` — vertex shader with position attribute and projection/view/model uniforms
- `fragmentShaderSource` — fragment shader with color uniform output

### `Manas.Graphics`

Type-safe interface to WebGL2, with opaque foreign types:

- `WebGL2Context`, `WebGLShader`, `WebGLProgram`, `WebGLBuffer`, `WebGLVertexArray`, `WebGLUniformLocation`, `WebGLFramebuffer`
- Functions for shader creation/compilation, program linking, buffer management, uniform setting, and draw calls
- All effectful operations return `Effect` values; nullable results use `Maybe`

### `Manas.WebXR`

Type-safe interface to the WebXR API:

- `XRSystem`, `XRSession`, `XRWebGLLayer`, `XRReferenceSpace`, `XRFrame`, `XRViewerPose`, `XRView`, `XRViewport`, `XRInputSource`, `XRHand`, `XRJointSpace`, `XRJointPose`
- Functions for session management, reference space, animation frame callbacks, hand tracking, and view/viewport access
- Nullable WebXR results wrapped in `Maybe` for safe handling

### `Main`

Application entry point orchestrating initialization and the render loop:

1. Obtain WebGL2 context from the canvas element
2. Check WebXR support and immersive-ar capability
3. Compile vertex and fragment shaders
4. Link the shader program and set up uniform locations
5. Create vertex array objects for the cube, left/right hand joints, and hand skeletons
6. Set up the "Start Experience" button to launch the XR session
7. In the XR frame callback: process hand input, detect pinch gestures, and render all scene elements

---

## Key Translation Patterns

### fp-ts Option/Either → PureScript Maybe/Either

**TypeScript (fp-ts):**
```typescript
import * as O from 'fp-ts/Option'
import * as E from 'fp-ts/Either'
import { pipe } from 'fp-ts/function'

const getCanvas = (): O.Option<HTMLCanvasElement> => {
  const canvas = document.getElementById('app') as HTMLCanvasElement | null
  return canvas ? O.some(canvas) : O.none
}
```

**PureScript:**
```purescript
import Data.Maybe (Maybe(..))

getCanvas :: Effect (Maybe WebGL2Context)
getCanvas = do
  mCtx <- getWebGL2Context "app"
  pure mCtx
```

### Imperative Error Handling → Pattern Matching

**TypeScript:**
```typescript
const gl = E.match(
  (error: Error) => { throw error },
  (gl: WebGL2RenderingContext) => gl
)(createContext(canvas))
```

**PureScript:**
```purescript
mGl <- getWebGL2Context "application"
case mGl of
  Nothing -> error "WebGL2 not supported"
  Just gl -> do
    -- continue with gl
```

### Mutable State → Effect Monad

All WebGL2 and WebXR side effects are wrapped in the `Effect` monad, making the boundary between pure computation and effectful I/O explicit in the types.

---

## Build & Run

### Prerequisites

- [PureScript compiler](https://github.com/purescript/purescript) (`purs` v0.15+)
- [Spago](https://github.com/purescript/spago) package manager
- Node.js 18+

### Install Dependencies

```bash
npm install -g purescript spago
spago install
```

### Compile

```bash
# Using spago
spago build

# Or directly with purs
purs compile 'src/**/*.purs' '.spago/p/*/src/**/*.purs' --output output
```

### Development Server

```bash
npm run dev
```

This starts a Vite dev server with HTTPS (required for WebXR).

### Usage

1. Open the application in a WebXR-capable browser
2. Click "Start Experience" to launch the immersive AR session
3. Use hand gestures to interact with the 3D environment

---

## Dependencies

### Removed (TypeScript)

| Package | Purpose |
|---------|---------|
| `fp-ts` | Functional programming abstractions (Option, Either, pipe) |
| `lodash` | Utility functions |
| `monocle-ts` | Optics/lenses for immutable data |
| `uuid` | Unique identifier generation |

### Added (PureScript)

| Package | Purpose |
|---------|---------|
| `prelude` | Core type classes and functions |
| `effect` | Effect monad for side effects |
| `console` | Console logging |
| `maybe` | Maybe type for nullable values |
| `either` | Either type for error handling |
| `arrays` | Array operations |
| `nullable` | FFI interop for nullable JavaScript values |

---

## Future Directions

With PureScript as the foundation, the project can leverage:

- **Halogen or React-Basic** for UI components if a non-WebXR interface is needed
- **purescript-aff** for asynchronous effects (network, file loading)
- **Custom type classes** for the categorical architecture described in the design docs
- **Optic libraries** (profunctor-lenses) as native PureScript replacements for monocle-ts
- **Effect tracking** to separate WebGL effects from pure computation in the type system
