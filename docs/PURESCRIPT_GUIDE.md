# PureScript Learning Guide — Manas

> A practical teaching document. Each section maps a concept from your TypeScript
> program to PureScript. Work through them in order. Comment with `<!-- -->`.

---

## 0. The Mental Model Shift

Before writing a single line, understand what is different about PureScript:

In TypeScript you write expressions that DO things. In PureScript you write
expressions that DESCRIBE things — descriptions that are later executed. This
is not pedantry. It changes how you think about every line.

| TypeScript | PureScript |
|---|---|
| `console.log("hi")` — does it now | `log "hi" :: Effect Unit` — describes it |
| `const x = null` — any value anywhere | `Maybe a` — explicit absence in the type |
| `async/await` | `Aff` monad |
| `Either` from fp-ts | `Either` built in, same idea |
| `pipe(x, f, g)` | `g $ f x` OR `x # f # g` |

The big idea: **effects are values**. `Effect Unit` is a description of a side
effect. `Aff Unit` is a description of an asynchronous side effect. You compose
these descriptions using the type system. When you call `main`, the runtime
executes the description.

---

## 1. The Syntax — Reading PureScript

### Types

```purescript
-- Type signatures use :: (not :)
name :: Type

-- Functions use -> with no parens required
add :: Int -> Int -> Int
add x y = x + y

-- Fully parenthesized reads left to right:
-- add takes an Int, returns (Int -> Int), which takes an Int, returns Int
-- This is currying. All functions are curried by default.
```

Compare to your TypeScript:
```typescript
// Your code:
const createVertexShader: (gl: WebGL2RenderingContext) => E.Either<Error, WebGLShader>

// PureScript equivalent shape:
createVertexShader :: WebGL2RenderingContext -> Either Error WebGLShader
-- Notice: no parens, no commas, types read left to right
```

### Records

```purescript
-- Your TypeScript:
type Model = { id: string, geometryId: string, position: Position }

-- PureScript record (nearly identical syntax!):
type Model = { id :: String, geometryId :: String, position :: Position }
-- The key difference: :: inside records, not :
```

### Maybe (your Option)

```purescript
-- fp-ts: O.some(x) / O.none
-- PureScript:
import Data.Maybe (Maybe(..))
x :: Maybe String
x = Just "hello"
y :: Maybe String
y = Nothing

-- Pattern matching (like O.match but more direct):
case maybeCanvas of
  Nothing -> -- handle absence
  Just canvas -> -- use canvas
```

### Either (same concept, same name)

```purescript
-- fp-ts: E.right(gl) / E.left(new Error(...))
-- PureScript:
import Data.Either (Either(..))
rightResult :: Either Error String
rightResult = Right "success"
leftResult :: Either Error String
leftResult = Left (error "failed")
-- Note: error :: String -> Error  (from Data.Exception)
```

---

## 2. Effects — The Core Concept

This is the most important thing to understand before writing any real code.

### Effect (synchronous)

Anything that talks to the real world synchronously returns `Effect a`.

```purescript
-- Your TypeScript:
const getApplicationCanvas = (): O.Option<HTMLCanvasElement> => {
  const el = document.getElementById('application') as HTMLCanvasElement | null
  return el ? O.some(el) : O.none
}

-- PureScript:
-- Step 1: getElementById is an Effect (it reads the DOM)
-- Step 2: it returns Maybe (the element might not exist)
getApplicationCanvas :: Effect (Maybe HTMLCanvasElement)
getApplicationCanvas = do
  maybeEl <- getElementById "application" document
  -- maybeEl :: Maybe Element
  -- We'd then need to cast to HTMLCanvasElement — done via FFI
  pure maybeEl  -- wraps the result back into Effect
```

Key rule: **`<-` unwraps** an `Effect a` inside a `do` block. `pure` **wraps** a
plain value back into `Effect`. Think of it as:
- `<-` = "run this effect and give me the result"
- `pure` = "wrap this pure value in Effect without doing anything"

### Aff (asynchronous)

Your `async/await` becomes `Aff`:

```purescript
-- Your TypeScript:
const supported = await xr.isSessionSupported('immersive-ar')

-- PureScript (using aff-promise):
import Promise.Aff (toAff)

isSessionSupported :: XRSystem -> XRSessionMode -> Aff Boolean
isSessionSupported xr mode = toAff (isSessionSupportedImpl xr mode)
-- isSessionSupportedImpl would be a foreign import returning a Promise Boolean
```

### do notation — sequencing effects

This is the key to writing effectful PureScript code:

```purescript
main :: Effect Unit
main = do
  -- Each line is an Effect. <- unwraps its result.
  maybeCanvas <- getApplicationCanvas
  case maybeCanvas of
    Nothing -> log "Canvas not found"
    Just canvas -> do
      maybeGl <- createGraphicLibraryContext canvas
      case maybeGl of
        Left err -> log ("Error: " <> show err)
        Right gl -> do
          log "GL context created"
          -- continue...
```

Notice: `do` inside a `case` arm — you can nest `do` blocks freely.

---

## 3. FFI — The Bridge to the Browser

This is how you map every WebGL/WebXR function. Your `WEBXR_FFI.md` already
explains the pattern. Here is the complete three-step recipe:

### The Recipe

**Step 1: Declare the foreign type in `.purs`**

```purescript
-- src/Graphics/WebGL.purs
foreign import data WebGL2RenderingContext :: Type
foreign import data WebGLShader :: Type
foreign import data WebGLProgram :: Type
```

`foreign import data` means: "this type exists at runtime, I don't define it".
It's an opaque token. PureScript knows nothing about its internals — which is
exactly right for a browser API handle.

**Step 2: Declare the foreign function in `.purs`**

```purescript
-- Notice the Effect wrapper — this is a side effect
foreign import getWebGL2ContextImpl
  :: (forall a. a -> Maybe a)  -- Just constructor
  -> (forall a. Maybe a)       -- Nothing constructor
  -> HTMLCanvasElement
  -> Effect (Maybe WebGL2RenderingContext)
```

The `(forall a. a -> Maybe a)` pattern passes the `Just` and `Nothing`
constructors into JS so JS can build a `Maybe` without importing PureScript.

**Step 3: Implement in the companion `.js` file**

```javascript
// src/Graphics/WebGL.js  (same folder, same base name)
export const getWebGL2ContextImpl = (just) => (nothing) => (canvas) => () => {
  // The () => at the end is the Effect wrapper — it delays execution
  const ctx = canvas.getContext('webgl2');
  return ctx ? just(ctx) : nothing;
};
```

**Step 4: Wrap cleanly in PureScript**

```purescript
getContext :: HTMLCanvasElement -> Effect (Maybe WebGL2RenderingContext)
getContext = getWebGL2ContextImpl Just Nothing
-- Point-free: we partially apply Just and Nothing,
-- leaving the canvas argument to be supplied by the caller
```

### The Effect Wrapper Rule

Any JS function that has side effects MUST be wrapped in `() =>` in JS:

```javascript
// WRONG — executes immediately, not an Effect:
export const createShader = (gl) => gl.createShader(gl.VERTEX_SHADER);

// CORRECT — wrapped in () =>, PureScript executes it when needed:
export const createShader = (gl) => () => gl.createShader(gl.VERTEX_SHADER);
```

The `() =>` in JS corresponds to `Effect` in the PureScript type signature.
Every effectful function MUST have this wrapper. This is the most common
mistake when writing FFI.

---

## 4. Your Pipeline — Translated

Here is your TypeScript pipeline in PureScript, step by step.

### The GL initialization pipeline

```purescript
-- Your TypeScript (paraphrased):
-- pipe(
--   createVertexShader(gl),
--   E.chain(vertexShader => initializeVertexShader(gl, vertexShader)),
--   E.match(
--     (error) => { throw error },
--     (vertexShader) => vertexShader
--   )
-- )

-- PureScript — do notation over Either:
import Data.Either (Either(..))

initVertexShader :: WebGL2RenderingContext -> Effect (Either Error WebGLShader)
initVertexShader gl = do
  -- createShader is an Effect that returns Maybe WebGLShader
  maybeShader <- createShader gl VERTEX_SHADER
  case maybeShader of
    Nothing -> pure (Left (error "Unable to create vertex shader"))
    Just shader -> do
      -- compile is an Effect Unit (a side effect with no return value)
      compile gl shader VERTEX_SHADER_SOURCE
      -- check the result
      success <- getShaderParameter gl shader COMPILE_STATUS
      if success
        then pure (Right shader)
        else do
          infoLog <- getShaderInfoLog gl shader
          _ <- deleteShader gl shader
          pure (Left (error ("Compile error: " <> infoLog)))
```

### Binding Either into Aff (your main IIFE becomes `launchAff_`)

```purescript
import Effect.Aff (launchAff_, Aff)
import Effect.Aff.Class (liftEffect)
import Data.Either (Either(..))

main :: Effect Unit
main = launchAff_ do
  -- launchAff_ runs Aff and ignores the result (like your IIFE)
  
  -- liftEffect brings an Effect into Aff
  canvas <- liftEffect $ do
    maybeCanvas <- getApplicationCanvas
    case maybeCanvas of
      Nothing -> throwError (error "Canvas not found")
      Just c  -> pure c
  
  gl <- liftEffect $ do
    maybeGl <- getContext canvas
    case maybeGl of
      Nothing -> throwError (error "WebGL2 not supported")
      Just g  -> pure g
  
  -- Async operations live in Aff naturally:
  supported <- isSessionSupported xr "immersive-ar"
  when (not supported) do
    throwError (error "WebXR not supported")
```

---

## 5. Types That Don't Exist Yet — Your FFI List

For your project, you will need to write FFI for ALL of these. This is your
work queue. Each one follows the same three-step recipe.

### Graphics (WebGL)

| Thing you need | PureScript | JS |
|---|---|---|
| The GL context | `foreign import data WebGL2RenderingContext :: Type` | `canvas.getContext('webgl2')` |
| `gl.createShader` | `createShader :: GL -> ShaderType -> Effect (Maybe WebGLShader)` | `gl.createShader(type)` |
| `gl.shaderSource` | `shaderSource :: GL -> WebGLShader -> String -> Effect Unit` | `gl.shaderSource(s, src)` |
| `gl.compileShader` | `compileShader :: GL -> WebGLShader -> Effect Unit` | `gl.compileShader(s)` |
| `gl.createProgram` | `createProgram :: GL -> Effect (Maybe WebGLProgram)` | `gl.createProgram()` |
| `gl.linkProgram` | `linkProgram :: GL -> WebGLProgram -> Effect Unit` | `gl.linkProgram(p)` |
| `gl.createBuffer` | `createBuffer :: GL -> Effect (Maybe WebGLBuffer)` | `gl.createBuffer()` |
| `gl.bufferData` | `bufferData :: GL -> BufferTarget -> Float32Array -> Usage -> Effect Unit` | `gl.bufferData(...)` |
| `gl.bufferSubData` | `bufferSubData :: GL -> BufferTarget -> Float32Array -> Effect Unit` | `gl.bufferSubData(...)` |
| `gl.drawArrays` | `drawArrays :: GL -> Primitive -> Int -> Int -> Effect Unit` | `gl.drawArrays(...)` |

### XR (WebXR)

| Thing you need | PureScript |
|---|---|
| `navigator.xr` | `foreign import data XRSystem :: Type` + `getXRSystem :: Effect (Maybe XRSystem)` |
| `xr.isSessionSupported` | `isSessionSupported :: XRSystem -> String -> Aff Boolean` |
| `xr.requestSession` | `requestSession :: XRSystem -> String -> SessionInit -> Aff XRSession` |
| `session.requestReferenceSpace` | `requestReferenceSpace :: XRSession -> String -> Aff XRReferenceSpace` |
| `session.requestAnimationFrame` | `requestAnimationFrame :: XRSession -> XRFrameCallback -> Effect Unit` |
| `frame.getViewerPose` | `getViewerPose :: XRFrame -> XRReferenceSpace -> Effect (Maybe XRViewerPose)` |
| `frame.getJointPose` | `getJointPose :: XRFrame -> XRJointSpace -> XRReferenceSpace -> Effect (Maybe XRJointPose)` |

---

## 6. The Render Loop — The Hard Part

The render loop is where PureScript and WebXR meet most awkwardly. The issue:
WebXR's `requestAnimationFrame` expects a plain JavaScript callback, but your
loop body is PureScript `Effect` code.

The pattern:

```purescript
-- In JS FFI, you expose a way to call PS Effect from JS:
-- src/XR/Session.js
export const requestAnimationFrame_ = (session) => (callback) => () => {
  session.requestAnimationFrame((time, frame) => {
    callback(time)(frame)();  // () runs the Effect
  });
};
```

```purescript
-- In PureScript:
foreign import requestAnimationFrame_
  :: XRSession
  -> (Number -> XRFrame -> Effect Unit)
  -> Effect Unit
```

Then your frame loop in PureScript:

```purescript
onXRFrame :: XRSession -> XRGLLayer -> RenderContext -> Ref Universe
          -> Number -> XRFrame -> Effect Unit
onXRFrame session glLayer ctx universeRef time frame = do
  -- Read universe
  universe <- read universeRef
  
  -- Read input (effects)
  hands <- readHandInput frame (session.inputSources) referenceSpace
  
  -- Update universe (pure)
  let newUniverse = updateUniverse universe hands
  
  -- Write new universe
  write newUniverse universeRef
  
  -- Render (effects)
  render ctx glLayer frame newUniverse
  
  -- Request next frame
  requestAnimationFrame_ session (onXRFrame session glLayer ctx universeRef)
```

Notice how this maps exactly to your `PLAN.md` Step 4 and 5 — the `Ref Universe`
is your mutable state cell, and the loop body does three things: read input,
update state, render.

---

## 7. Module Organization — Where Things Go

PureScript uses modules with dot-notation paths. The module name must match
the file path.

```
src/
  Main.purs                  -- module Main
  Graphics/
    Context.purs             -- module Graphics.Context
    Context.js               -- FFI for Graphics.Context
    Shader.purs              -- module Graphics.Shader
    Shader.js
    Buffer.purs              -- module Graphics.Buffer
    Buffer.js
    VAO.purs                 -- module Graphics.VAO
    VAO.js
  XR/
    System.purs              -- module XR.System
    System.js
    Session.purs             -- module XR.Session
    Session.js
    Input.purs               -- module XR.Input
    Input.js
  Domain/
    Types.purs               -- module Domain.Types  (Universe, Model, etc.)
    Gesture.purs             -- module Domain.Gesture (pure gesture logic)
    Math.purs                -- module Domain.Math (pure matrix math)
```

**Start flat, refactor into this.** Your `PLAN.md` says: "Do not separate into
multiple files yet." That's right. But knowing the target structure helps you
name things correctly from the start.

---

## 8. Your Next Steps — Concrete and Ordered

This maps to your `PLAN.md` steps but reframed for PureScript specifically.

### Step 0: Read the language (before writing)
- **[PureScript by Example](https://book.purescript.org/)** — the official free book. Read chapters 1-5 now. Chapters 6-8 later.
- **[Pursuit](https://pursuit.purescript.org/)** — the package documentation. Bookmark it. Every standard library function is here.
- **Try in the REPL**: run `spago repl` and experiment with expressions. This is faster than edit-compile-run.

### Step 1: Translate the pure math (no FFI needed)

Write `src/Domain/Math.purs`. This is your matrix math from `PLAN.md` Step 1.
Pure functions. No `Effect`. No browser. The type:

```purescript
module Domain.Math where

type Vec3 = { x :: Number, y :: Number, z :: Number }
type Mat4 = Array Number  -- 16 elements, column-major

identityMatrix :: Mat4
identityMatrix = [1.0,0.0,0.0,0.0, 0.0,1.0,0.0,0.0, 0.0,0.0,1.0,0.0, 0.0,0.0,0.0,1.0]

multiplyMat4 :: Mat4 -> Mat4 -> Mat4
multiplyMat4 a b = -- implement 4x4 matrix multiplication

translationMatrix :: Vec3 -> Mat4
translationMatrix v = -- embed translation into 4th column
```

This is the highest-value first task. It's pure, testable, has no FFI complexity,
and unblocks everything in `PLAN.md`.

### Step 2: Write your first FFI — the canvas

Write `src/Graphics/Context.purs` and `src/Graphics/Context.js`. Target:

```purescript
getApplicationCanvas :: Effect (Maybe HTMLCanvasElement)
getContext :: HTMLCanvasElement -> Effect (Maybe WebGL2RenderingContext)
enableDepthTest :: WebGL2RenderingContext -> Effect Unit
```

Three functions. Three FFI bridges. When these work, you have provably connected
PureScript to the GPU.

### Step 3: Translate the GL initialization pipeline

Each `createX` / `initializeX` function pair from your TypeScript becomes a
PureScript function + JS FFI pair. Work through them in order:

1. Shaders (`createShader`, `compileShader`, `getShaderParameter`)
2. Program (`createProgram`, `attachShader`, `linkProgram`)
3. Buffers (`createBuffer`, `bufferData`)
4. VAOs (`createVertexArray`, `vertexAttribPointer`)

### Step 4: Write the XR FFI

Hardest FFI. Work through these:

1. `getXRSystem :: Effect (Maybe XRSystem)`
2. `isSessionSupported :: XRSystem -> String -> Aff Boolean`
3. `requestSession :: XRSystem -> String -> Aff XRSession`
4. `requestAnimationFrame_ :: XRSession -> Callback -> Effect Unit`
5. `getViewerPose :: XRFrame -> XRReferenceSpace -> Effect (Maybe XRViewerPose)`
6. `getJointPose :: XRFrame -> XRJointSpace -> XRReferenceSpace -> Effect (Maybe XRJointPose)`

### Step 5: Wire the render loop

Connect everything in `Main.purs` using `launchAff_` and `Ref` for the Universe.

---

## 9. Common Compiler Errors and What They Mean

| Error | What it means |
|---|---|
| `Could not match type Effect a with a` | You forgot `<-` to unwrap an `Effect` |
| `Unknown value foo` | Import is missing — add it to the `import` list |
| `Could not match type a with b` | Type mismatch — check your types with `:t expr` in the REPL |
| `The value of foo is undefined` | FFI bug — the JS function isn't exported correctly |
| `No type class instance for Show a` | You're trying to print a type that doesn't have `show` |
| `Partial function` | You pattern-matched non-exhaustively — handle all cases |

---

## 10. The Single Most Important Thing

You already understand the architecture. Your `PLAN.md`, `FOUNDATIONS.md`, and
`RESOURCES.md` have mapped the systems, the naming conventions, the state model,
and the resource lifecycle better than most engineers do after years on a project.

What PureScript adds is:
1. **The type system makes your architecture visible** — `Either Error WebGL2RenderingContext`
   literally says in the type what your functions already try to say in names.
2. **The FFI makes the boundary explicit** — every place you cross into browser
   land is marked. No silent coercions or casts.
3. **`Effect` and `Aff` make the effect architecture real** — you said in
   `FOUNDATIONS.md` that effects are at the boundary. PureScript enforces this.

You are not learning PureScript from scratch. You are learning the syntax for
things you already understand conceptually. That is a much easier task.

---

*Work through sections 1-3 first. Then write Step 1 from section 8.*
*Comment anywhere with `<!-- -->`.*
