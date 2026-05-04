# Manas — TODO

## Phase 1: Make the invisible visible
No code changes. Only comments and analysis.

- [x] Comment ForeignUtils.purs by functional block
  - Two layers: Primitives (TypedArray machinery) / Linear Algebra (mathematical operations)
  - Sub-blocks: [TypedArray Types + Constructors], [TypedArray Access], [TypedArray Mutation], [TypedArray Conversion]
  - Sub-blocks: [Vec3 Operations], [Mat4 Operations], [Mat4 Queries], [Spatial Operations]
  - Annotated: type dishonesty (forall a), Effect inconsistency, totality issues, Phase 2 names, design choices, composition opportunities
- [x] Comment ForeignUtils.js with matching blocks
- [x] Verify Main.purs section comments reflect discovered layers
  - Comment cleanup pass removed addressed/speculative comments; section headers preserved as the discovered layers
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

- [x] Vec3.purs + Vec3.js → `src/Math/Vec3.{purs,js}`
- [x] Mat4.purs + Mat4.js → `src/Math/Mat4.{purs,js}`
- [x] Geometry.purs + Geometry.js → `src/Math/Geometry.{purs,js}` (rayTriangleIntersect; emerged during refactor)
- [x] Primitives module extracted (TypedArray machinery: getAt, setAt, copyInto, subarray, conversions) → `src/Primitives.{purs,js}`
- [x] ForeignUtils dissolved
- [x] Main.purs migrated to Vec3, Mat4, Geometry, Primitives
- [ ] **Outstanding**: migrate `Geometry.vertices` from `Array Number` to `Array Vec3` to resolve `fromMaybe`-paranoia in `getVertex` and `rayMeshIntersect` (Main.purs:297-324). Cross-cutting: touches Geometry type, vertex iteration, and `uploadGeometry` (which flattens back to Float32Array for the GPU).

## Phase 2.5: Restructure GPU resource setup
uploadGeometry fuses structure setup + data upload. Separate into two steps.

- [ ] Step 1: configure VAO + buffers (structure) → GPUHandle
- [ ] Step 2: upload/update data into existing GPUHandle
- [ ] uploadGeometry = step 1 composed with step 2 (static, STATIC_DRAW)
- [ ] Hand tracking pattern = step 1 at init (DYNAMIC_DRAW) + step 2 per frame
- [ ] Design signatures before implementing
- [ ] Enables future modifiable geometry

## Phase 2.75: Shader compilation extraction (done)
Delivered as `makeShader` and `makeProgram` in WebGL2 idiomatic. Wave 3-4 of the refactor expanded the layer further with `makeBuffer`, `makeVertexArrayObject`, `findUniformLocation`.

- [x] makeShader :: forall m. MonadEffect m => RenderingContext -> ShaderType -> String -> ExceptT String m Shader
- [x] makeProgram :: forall m. MonadEffect m => RenderingContext -> Shader -> Shader -> ExceptT String m Program
- [x] All live in WebGL2 idiomatic layer, not in Main

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

## Phase 7+: Creative trajectory
Phases 1-6 are the technical refactor. Phases 7+ are creative direction — what the project becomes once foundations are solid. Trajectory rather than strict ordering: textures and UI lean on each other; illumination is optional alongside any of them.

## Phase 7: Controllers + gesture intent
Faster testing on couch, plus the substrate to abstract gesture *intent* from gesture *mechanism*.

- [ ] Detect XRInputSource type (hand vs gamepad)
- [ ] Read controller buttons, triggers, grips, thumbsticks
- [ ] Define abstract gesture types: Trigger, Grab, TwoHandTrigger, TwoHandGrab, Drag, Hover, Point
- [ ] Map hand mechanism → abstract gesture
- [ ] Map controller mechanism → abstract gesture
- [ ] Replace direct pinch-distance checks in Main with abstract gesture events
- [ ] Both modalities coexist (hands + controllers active simultaneously)
- The vocabulary lives at intent level — the right level for an instrument.

## Phase 8: Textures
Visual decoration applied to objects to enrich their appearance. A cube wearing a brick texture is still a cube — geometry is primal, texture is overlay. Imported and generated coexist; neither is privileged. Lets primitive objects participate in scenes that depict things (a brick wall, a tiled floor, a labeled object) without sculpting detail into geometry.

- [ ] Raw layer: createTexture, deleteTexture, bindTexture, texImage2D (image source + data source variants), texParameteri, generateMipmap, activeTexture
- [ ] Idiomatic constructors: makeTextureFromImage (HTMLImageElement → Texture) and makeTextureFromData ({width, height, data} → Texture). Both wrap create + bind + upload + parameters + mipmap as one call.
- [ ] Add UV coordinates to Geometry — per-vertex `vec2` attribute. Bake sensible default UV unwrappings per primitive (cube: six-face; sphere: equirectangular; pyramid: triangle-net).
- [ ] uploadGeometry configures both position and UV attributes; VAO has two attribute pointers.
- [ ] Vertex shader: `aUV` attribute, `vUV` varying. Fragment shader: `uniform sampler2D uTex`, `texture(uTex, vUV)`.
- [ ] TextureId + registry (lives in RenderState alongside geometry registry — same Phase 4 pattern)
- [ ] Scene objects gain optional TextureId reference; default 1×1 white texture so shader works uniformly
- [ ] Per-draw-call texture binding in render loop
- [ ] First textures: 1×1 white (default), one imported (brick image), one procedural (checker pattern computed in shader, no upload)
- Procedural fragment-shader effects (noise, fresnel, gradients) are first-class alongside imported textures — they're "textures" in the same pipeline slot, just generated per-fragment instead of sampled.

## Phase 9: UI as world (surfaces)
The world is uniform — UI is composition that invokes behavior, not an interface overlaid on the scene.

- [ ] Surface primitive — flat (later curved) region of composition that carries text, texture, interaction
- [ ] Text rendering: glyph atlas as imported texture, surface as canvas
- [ ] Interactive surfaces: emit events on proximity, pinch, drag (via Phase 7 gesture intents)
- [ ] First UI artifact: the spawn palette — palm-up reveals labeled, textured, interactive surfaces; pinch to spawn
- Position: button = interactive surface with label. Slider = surface with draggable child. Panel = surface holding surfaces. The UI vocabulary is one primitive composed differently.

## Phase 10: Illumination
Tool for legibility *and* aesthetic. Default look is marble-like: pristine white/black with shine. Phong/Blinn-Phong is the right level — PBR is overkill.

- [ ] Per-vertex normals on geometry (third attribute alongside position + UV). Flat shading replicates per face; smooth shading averages at vertices. Decide per-primitive.
- [ ] Vertex shader passes interpolated normal as varying.
- [ ] Fragment shader: ambient + diffuse (Lambert: `max(dot(N, L), 0)`) + specular (Blinn-Phong: `pow(max(dot(N, H), 0), shininess)` with shininess ~64-128 for polished).
- [ ] One directional light fixed in scene to start; uniforms for direction + color.
- [ ] Optional: fresnel rim glow (`1 - dot(N, V)`) — edges brighten, looks expensive, costs nothing.
- [ ] Optional: cubemap environment reflection — what makes polished surfaces genuinely shiny vs just specular-highlighted. The marble secret ingredient.
- [ ] Alternate aesthetic — normal-as-color (`color = abs(normalize(normal))`): mathematical/diagrammatic look. Useful for debug and possibly as a switchable mode later.
- [ ] Placeable lights as scene-graph objects (after Phase 11)
- Don't pursue PBR — imports a video-game material model that competes with sculptural restraint. Phong is enough; ~15 fragment-shader lines for marble-grade light.

## Phase 11: Scene graph
Hierarchical composition. Geometry as referenced resource, scene objects as instances. Transform propagation falls out of the math.

- [ ] Geometry referenced by id (extends Phase 4 GeometryId bridge)
- [ ] SceneObject = { transform, content } where content = Leaf GeometryId | Composition (Array SceneObject)
- [ ] World transform computed at render time: `parent.world ∘ node.local` — no stored mutation propagation
- [ ] Manipulation of parent updates descendants for free (rotate parent → all children rotate)
- [ ] Bake operation: `child.local := child.world; reparent to root` — for the CAD "lock" gesture
- [ ] Tree first (one parent per child); DAG (shared instances) when needed
- [ ] Finite for now (no self-reference)
- Future direction: recursive compositions with stop conditions (depth, scale, distance, predicate) — same data type, just allow self-references at traversal. Bridges scene graph to generative art (fractals, L-systems, IFS) as a direct extension.

## Phase 12: CAD construction loop
Vertex/edge/face → composition. The original AutoCAD/Blender vision in spatial form.

- [ ] Vertex placement by pinch (in-air)
- [ ] Edge by two-vertex pinch (one per hand)
- [ ] Face by closed selection of edges/vertices
- [ ] Snap-to-vertex during placement (proximity threshold ε)
- [ ] Lock gesture → composition (frozen subtree as single manipulable object via Phase 11 bake)
- [ ] Compositions appear in spawn palette alongside primitives (Phase 9)
- Design question to decide before compositions are reused: when a composition is used inside another, does it reference (edits propagate) or copy (independent)? Blender: copy with linked-instance opt-in. AutoCAD: block references. Affects whether a fractal can be built as recursive self-reference.

## Bugs / Inconsistencies found
- [ ] nextObjectId starts at 1 but initial cube uses SceneObjectId "cube-instance-1" (string, not from counter)
  - First spawn generates SceneObjectId "1" — works by accident, not design
  - Fix: either use counter for initial cube too, or start counter at a different value
- [ ] gl_POINTS rendered with constant `gl_PointSize` stay the same screen-pixel size regardless of distance, so distant points appear oversized relative to perspective-shrinking geometry
  - Affects hand joint rendering (or any point-rendered vertices)
  - Fix: in vertex shader, scale by clip-space depth — `gl_PointSize = K / gl_Position.w` (or compute view-space distance and divide)
  - Alternative: render points as small geometry (quads or spheres) instead of gl_POINTS

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
- Model palette / selection UI — superseded by Phase 9 (UI as world / spawn palette)
- Tick portability: readInput is the only XR-coupled step, rest is universal
  - Enables browser mode without VR for viewing/teaching

## Future (no order, do when needed)
- [ ] Type class for shared vector operations (if Vec4 or other Vec types appear)
- [ ] Type-level Int exploration (Vec :: Int -> Type)
- [x] WebGL2 two sub-layers fully formalized
- [x] WebXR two sub-layers formalized
- [ ] WebGL2 type fixes: replace `forall a` with typed arrays, decide on Int aliases
- [ ] WebGPU migration (RenderState + executeRenderCommands swap, WorldState unchanged)
- [ ] Interpreter pattern via purescript-run
- [ ] isPointInsideMesh (real collision detection)
- [ ] Review two-hand manipulation math on paper
- [ ] Map performance optimization (if needed with many objects)

### Backlog from Phase B (lighting on device)
- [ ] **Shadow casting**: an object between the emitter and another object should occlude light. Today the fragment shader has no occlusion test — light radiates through everything. Approach: shadow mapping — render scene from the emitter's POV into a depth texture, sample in the main shader to test "is this fragment visible from the light?". Substantial (~1-2 sessions).
- [ ] **Two-hand grab on different objects**: today pinching with both hands on the same object enters TwoHandManipulate (combined translate + rotate + scale). Desired: pinch on object A with one hand and on object B with the other → both move independently in parallel. TwoHandManipulate remains for explicit dual-grip on one object; the default for "different objects" is parallel one-hand each. Refactor of the interaction state machine.
- [ ] **Multiple light sources**: extend `u_lightPosition` / `u_lightFalloff` from scalars to fixed-size arrays; loop over emissive scene objects in the fragment shader, accumulate contributions. Cap at ~8 lights via `MAX_LIGHTS`. ~1 hour when needed.

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
