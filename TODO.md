# Manas — TODO

## Phase 1: Make the invisible visible
No code changes. Only comments and analysis.

- [ ] Comment ForeignUtils.purs by functional block
  - [TypedArray Primitives]
  - [Vec3 Operations]
  - [Mat4 Operations]
  - [Mat4 Queries]
  - [Spatial Operations]
- [ ] Comment ForeignUtils.js with matching blocks
- [ ] Verify Main.purs section comments reflect discovered layers
- [ ] Totality audit: find every fromMaybe, !!, incomplete pattern match in Main
  - Classify each: programmer error vs system condition
  - Add inline comments marking decisions

## Phase 2: Linear algebra foundation
Create Vec3 and Mat4 modules. ForeignUtils dissolves.

- [ ] Vec3.purs + Vec3.js
  - newtype Vec3 with private constructor
  - Smart constructors: vec3
  - Operations: sub, add, dot, cross, normalize, distance, midpoint, scale
  - Rename: sub3→sub, get3DDistance→distance, etc.
  - Compile and verify
- [ ] Mat4.purs + Mat4.js
  - newtype Mat4 with private constructor
  - Smart constructors: identity, translation, rotation
  - Operations: multiply, transformPoint
  - Queries: translationOf, scaleOf
  - Rename: multiplyMatrix4x4→multiply, getTranslationFromMatrix→translationOf, etc.
  - Compile and verify
- [ ] Migrate ForeignUtils → Vec3 + Mat4
  - What remains (TypedArray primitives, copyInto, subarray) stays as TypedArray module or in ForeignUtils
- [ ] Update Main.purs to use Vec3 and Mat4
  - Transform fields: Float32Array → Vec3 / Mat4
  - composeModelMatrix → interpretTransform
  - addCubeToScene → addObjectToScene (parametrize by GeometryId)
  - generateRandomTranslationMatrix4x4Float32 → randomPosition :: Effect Vec3
  - All naming changes propagate

## Phase 2.5: Restructure GPU resource setup
uploadGeometry fuses structure setup + data upload. Separate into two steps.

- [ ] Step 1: configure VAO + buffers (structure) → GPUHandle
- [ ] Step 2: upload/update data into existing GPUHandle
- [ ] uploadGeometry = step 1 composed with step 2 (static, STATIC_DRAW)
- [ ] Hand tracking pattern = step 1 at init (DYNAMIC_DRAW) + step 2 per frame
- [ ] Design signatures before implementing
- [ ] Enables future modifiable geometry

## Phase 2.75: Shader compilation extraction
Extract repeated WebGL2 patterns from main into WebGL2 idiomatic layer.

- [ ] compileShader :: RenderingContext -> ShaderType -> String -> ExceptT String Effect Shader
  - Vertex + fragment shader compilation are the same pattern (lines 576-602)
- [ ] linkProgram :: RenderingContext -> Shader -> Shader -> ExceptT String Effect Program
  - Program creation + linking + error handling (lines 604-620)
- [ ] These live in WebGL2 idiomatic layer, not in Main

## Phase 3: Separate initialization from render loop
ExceptT out of the hot path. Pipeline stages become visible.

- [ ] Remove ExceptT from tick
  - Replace with direct case/Maybe pattern matching
  - Keep ExceptT only in initialization (main, runExperience)
- [ ] Comment pipeline stages in tick
  - [Read Input] — platform-specific (XR today, browser later)
  - [Detect Gestures] — platform-independent
  - [Update Interaction] — platform-independent
  - [Update World State] — platform-independent
  - [Render] — GPU-specific (WebGL2 today, WebGPU later)

## Phase 4: Separate WorldState from RenderState
The universe is independent of the medium it's projected in.

- [ ] Extract GPU resources out of WorldState
  - WorldState: geometries, sceneObjects, nextObjectId, inputs, interaction (pure, universal)
  - RenderState: gpuHandles, shader locations, hand render resources (GPU-specific)
  - Shared key: GeometryId bridges the two
- [ ] This makes WorldState portable: WebGL2, WebGPU, canvas2D, or no rendering at all
- [ ] tick pipeline becomes: readInput (platform) → update WorldState (universal) → render (GPU)

## Phase 5: RenderCommand pipeline
Separate "decide what to render" from "render."

- [ ] Define RenderCommand type
- [ ] generateRenderCommands :: WorldState → Array RenderCommand (pure, universal)
- [ ] executeRenderCommands :: RenderState → Array RenderCommand → Effect Unit (GPU-specific)
- [ ] tick becomes composition of pipeline stages

## Phase 6: Transform refactor
Domain types for transforms, GPU conversion at the boundary.

- [ ] Study quaternions (structure, why they represent rotations, slerp)
- [ ] Define rotation representation (quaternion or axis-angle, decide)
- [ ] Transform uses Vec3 for position, new rotation type, Vec3 or Number for scale
- [ ] interpretTransform converts domain Transform → Mat4 at render boundary

## Bugs / Inconsistencies found
- [ ] nextObjectId starts at 1 but initial cube uses SceneObjectId "cube-instance-1" (string, not from counter)
  - First spawn generates SceneObjectId "1" — works by accident, not design
  - Fix: either use counter for initial cube too, or start counter at a different value

## Observations from code review (to be addressed in relevant phases)
- Shader locations could be a record type (ShaderLocations) but must not couple WorldState to WebGL2
  - Lives in RenderState, not WorldState (Phase 4)
- runExperience captures many external refs (locations, VAOs, buffers, worldStateRef)
  - Clean up when ShaderLocations + RenderState records exist
- leftHandVertices/rightHandVertices live outside WorldState but are conceptually input state
  - Tension: they're mutated in-place (copyInto) for performance
  - Resolve when separating WorldState from RenderState
- "immersive-ar" hardcoded as string — future: SessionMode ADT
- "local" reference space limits movement — future: "local-floor" or "bounded-floor"
- Model palette / selection UI — future feature
- Tick portability: readInput is the only XR-coupled step, rest is universal
  - Enables browser mode without VR for viewing/teaching

## Future (no order, do when needed)
- [ ] Type class for shared vector operations (if Vec4 or other Vec types appear)
- [ ] Type-level Int exploration (Vec :: Int -> Type)
- [ ] WebGL2 two sub-layers fully formalized
- [ ] WebXR two sub-layers formalized
- [ ] WebGL2 type fixes: replace `forall a` with typed arrays, decide on Int aliases
- [ ] WebGPU migration (RenderState + executeRenderCommands swap, WorldState unchanged)
- [ ] Interpreter pattern via purescript-run
- [ ] isPointInsideMesh (real collision detection)
- [ ] Review two-hand manipulation math on paper
- [ ] Map performance optimization (if needed with many objects)

---

## Reference (not tasks)

### Study list
- "Parse, Don't Validate" — Alexis King
- Smart constructors and abstract types in PureScript
- Type class laws (what laws should Vector have?)
- Quaternions as structure
- Parametricity and free theorems

### Axioms (derive principles from these)
- Honest representation: code means what it says
- Composition: parts combine predictably
- Minimal knowledge: each part knows only what it needs
- Essential over accidental: fight the right complexity

### Layers (dependency direction: downward only)
- Foundational: Linear Algebra (Vec3, Mat4) — accessible by all
- Geometry: vertices, indices, topology, meshes
- Transform: position, rotation, scale (domain types)
- Scene: objects, spatial queries, interaction
- Render boundary: interpret domain → GPU commands
- GPU bindings: WebGL2/WebGPU, WebXR
