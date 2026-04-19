# Manas — TODO

## Phase 1: Make the invisible visible
No code changes. Only comments and analysis.

- [x] Comment ForeignUtils.purs by functional block
  - Two layers: Primitives (TypedArray machinery) / Linear Algebra (mathematical operations)
  - Sub-blocks: [TypedArray Types + Constructors], [TypedArray Access], [TypedArray Mutation], [TypedArray Conversion]
  - Sub-blocks: [Vec3 Operations], [Mat4 Operations], [Mat4 Queries], [Spatial Operations]
  - Annotated: type dishonesty (forall a), Effect inconsistency, totality issues, Phase 2 names, design choices, composition opportunities
- [x] Comment ForeignUtils.js with matching blocks
- [ ] Verify Main.purs section comments reflect discovered layers
- [x] Totality audit: find every fromMaybe, !!, incomplete pattern match in Main
  - Classified each: programmer error vs system condition
  - Two real issues: getVertex and rayMeshIntersect silence out-of-bounds with fromMaybe
    - Root cause: flat Array Number can't express "this index is valid"
    - Resolves in Phase 2 when geometry becomes Array Vec3
  - Shader error fromMaybe: correct (system boundary, GPU driver can return null)
  - handedness string match: correct (system boundary), but candidate for parse-don't-validate (String → Handedness ADT)
  - All Map.lookup and InteractionMode pattern matches are total

## Phase 2: Linear algebra foundation
Create Vec3 and Mat4 modules. ForeignUtils dissolves.

- [ ] Vec3.purs + Vec3.js
  - newtype Vec3 with private constructor
  - Smart constructors: vec3
  - Extract what exists (used in Main today):
    - sub, add, dot, cross, normalize, midpoint, distance
    - Rename: sub3→sub, get3DDistance→distance, normalize3→normalize, etc.
  - Add when needed (not used yet — reference for future):
    - zero: identity element of addition; makes normalize3's silent [0,0,0] explicit
    - scale: scalar multiplication; unlocks lerp, spring physics, weighted averages
      - lerp t a b = add (scale (1-t) a) (scale t b) → smooth hand tracking, animated transitions
      - force = scale (-k) displacement → spring/snap-back interactions
      - center of mass of N points = weighted sum via scale + add
    - negate: reverse direction; needed for reflection, explicit direction reversal
      - reflect v n = sub v (scale (2 * dot v n) n) → bounce, mirror effects
    - length: magnitude; sqrt(dot v v), total (always >= 0)
      - guard normalize: if length v > epsilon then normalize else fallback → totality solved
      - speed = length velocity → gesture speed detection (tap vs drag)
      - already implicitly used: sqrt(dot rotationAxis rotationAxis) on line 544
  - Algebraic structure: add + zero + negate = abelian group; + scale = vector space; + dot = inner product space
  - Derivation hierarchy: dot → length → distance (each derived from the one before)
  - Totality question: normalize :: Vec3 → Maybe Vec3? Decide when extracting.
  - Compile and verify
- [ ] Mat4.purs + Mat4.js
  - newtype Mat4 with private constructor
  - Extract what exists (used in Main today):
    - multiply, fromTranslation, fromAxisAngle, transformPoint, translationOf, scaleOf
    - identity — currently defined in Main as identityMatrix4x4Float32, belongs here
    - fromScale — Main builds scale matrices manually (lines 530-535), replaces real code
    - Rename: multiplyMatrix4x4→multiply, getTranslationFromMatrix→translationOf, etc.
  - Add when needed (not used yet — reference for future):
    - inverse: Mat4 → Mat4; unlocks efficient ray casting and space conversions
      - Current rayMeshIntersect transforms every vertex to world space (3×N transforms per mesh)
      - With inverse: transform ray to local space once (1 transform), test against local vertices
      - For 12-triangle cube: 1 transform vs 36. For complex models: critical.
      - Theory: covariance vs contravariance — push geometry forward or pull query backward
      - Also needed for: camera math (view matrix = inverse of camera model matrix)
    - fromScale3 :: Vec3 → Mat4 — non-uniform scale (stretch along one axis); uniform is enough for now
  - Monoid structure: (Mat4, multiply, identity) — associative + identity element
  - Constructors family: fromTranslation + fromAxisAngle + fromScale = T·R·S
    - These don't commute: T·R·S ≠ S·R·T (non-abelian)
  - Compile and verify
- [ ] Migrate ForeignUtils → Vec3 + Mat4
  - What remains (TypedArray primitives, copyInto, subarray) stays as TypedArray module or in ForeignUtils
- [ ] Update Main.purs to use Vec3 and Mat4
  - Transform fields: Float32Array → Vec3 / Mat4
  - composeModelMatrix → interpretTransform
  - addCubeToScene → addObjectToScene (parametrize by GeometryId)
  - generateRandomTranslationMatrix4x4Float32 → randomPosition :: Effect Vec3
  - makeTranslationMatrix dissolves — it only exists because getAt is Effect; with Vec3, just use fromTranslation
  - get3DDistanceFromMatrix dissolves — becomes distance p (translationOf m)
  - Manual scale matrix (lines 530-535) becomes fromScale scaleFactor
  - sqrt(dot rotationAxis rotationAxis) becomes length rotationAxis
  - identityMatrix4x4Float32 moves to Mat4.identity
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

## Observations from Phase 1 analysis

- Effect inconsistency in ForeignUtils: getAt and get3DDistance are Effect, but sub3/dot3/toArray are pure — all read from Float32Array without mutating. Phase 2 must make a conscious choice about purity boundary at FFI.
- float32Array/uint16Array use `forall a` but only accept Array Number — type-dishonest. Phase 2 fixes with smart constructors.
- axisAngleRotationMatrix takes cos/sin separately, not the angle — caller does trig. Intentional or accidental? Decide in Phase 2.

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
- Parametricity and free theorems (connects to: forall a dishonesty in FFI, Reynolds' abstraction theorem)
- Vector spaces: abelian group (add, zero, negate) + scalar multiplication = vector space
- Inner product spaces: dot product → norm (length) → metric (distance) — derivation hierarchy
- Monoids and groups: (Mat4, multiply, identity) as monoid; invertible matrices as group GL(4,ℝ)
- Referential transparency: when named primitives clarify intent vs when composition suffices
- Totality: total functions (length: always valid) vs partial (normalize: zero vector edge case)

### Composition recipes (what primitives unlock together)
- scale + add → lerp (interpolation, animation, smooth tracking)
- scale + dot + sub → reflect (bounce, mirror effects)
- length + normalize → safe normalization (totality via guard)
- inverse + transformPoint → efficient space conversion (ray casting, camera)
- lerp + tick → animation system (smooth transitions between states)
- scale + sub → spring force (snap-back, elastic interactions)
- Each new primitive doesn't add one capability — it multiplies the compositions available

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
