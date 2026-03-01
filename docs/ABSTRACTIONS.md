# Manas — System Abstractions: Camera, Session, Input, Capabilities

> Add your comments with <!-- -->. This document explores how systems should
> be defined so they can be extended without being rewritten.

---

## I. Why Abstractions Exist — The Right Reason

An abstraction is not simplification. It is generalization — replacing a
specific thing with the essential shape of that thing, so the essential shape
can have multiple concrete implementations.

The wrong reason to abstract: "this code is complex, let me hide it."
Hiding complexity only moves it — it doesn't remove it.

The right reason to abstract: "this code does something that could be done
in multiple ways, and I want the rest of the system to work with any of them."

For Manas:
- The way cameras are provided could be: XR stereo views, a desktop canvas,
  a recorded playback. Abstracting the camera means the renderer doesn't care.
- The way inputs arrive could be: XR hands, mouse, keyboard, controllers.
  Abstracting input means the update function doesn't care.
- The XR session lifecycle could become a network session, a local file, or
  live collaboration. Abstracting sessions means the app loop doesn't care.

Each abstraction is a decision: "the rest of the system will never see the
specific thing, only the shape of it." Once that decision is made, the specific
things can change, multiply, or disappear — and the rest of the system is unchanged.

<!-- YOUR THOUGHTS: -->


---

## II. The Camera Abstraction

### What a Camera Is

A camera is everything the renderer needs to produce one view of the world.
It is not a lens or a physical device. It is a mathematical specification:

```
Camera = {
  projectionMatrix: Mat4    // how 3D space maps to screen space (perspective)
  viewMatrix:       Mat4    // where the camera is and what it's looking at
  viewport:         Viewport // which region of the framebuffer to draw to
}

Viewport = {
  x:      number   // left edge in pixels
  y:      number   // bottom edge in pixels
  width:  number
  height: number
}
```

This is all the renderer needs per camera. The renderer doesn't know whether
this camera came from an XR headset or a desktop canvas.

### Where Cameras Come From — Frame Producers

Each rendering context provides cameras differently, but each must provide
the same shape:

**XR stereo session:**
```
XRPose.views → [leftEyeView, rightEyeView]
→ Camera[] of length 2
leftEyeView.projectionMatrix  → camera.projectionMatrix
leftEyeView.transform.inverse → camera.viewMatrix
xrLayer.getViewport(view)     → camera.viewport
```

**Desktop preview:**
```
Computed from: canvas size, target position (0,0,0), FOV
→ Camera[] of length 1
buildPerspectiveMatrix(fov, aspect, near, far) → camera.projectionMatrix
buildViewMatrix(eye, target, up)               → camera.viewMatrix
{ x:0, y:0, width: canvas.width, height: canvas.height } → camera.viewport
```

**Recorded playback:**
```
Stored Camera[] per frame, loaded from disk
→ Camera[] of length 1 or 2
Exactly the same as XR, but the data came from a recording
```

### The Renderer Signature

Once you have this abstraction, the render function becomes:

```
render :: (RenderContext, Universe, Camera) → void
```

And the frame loop becomes:

```
getCamerasForFrame(session) → Camera[]
renderAll :: (RenderContext, Universe, Camera[]) → void
  = cameras.forEach(camera => render(ctx, universe, camera))
```

The renderer is identical for XR, desktop, and recorded playback. Only
`getCamerasForFrame` differs.

<!-- YOUR THOUGHTS: -->


---

## III. The Session Abstraction

### What a Session Is

A session is the runtime envelope that:
1. Provides cameras each frame (where to render from)
2. Provides a framebuffer to draw into (where to render to)
3. Drives the frame loop (when to render)
4. Provides input events (what is happening)

In WebXR, the session IS the `XRSession`. But Manas needs to support
non-XR running. The abstraction extracts the essential behavior:

```
Session = {
  // Request a frame callback — like requestAnimationFrame for XR
  requestFrame: (callback: FrameCallback) → void

  // Get cameras for this frame
  getCameras: (frame: any) → Camera[]

  // Get the framebuffer handle to render into (null = default canvas)
  getFramebuffer: (frame: any) → WebGLFramebuffer | null

  // Clean up when session ends
  end: () → void
}

FrameCallback = (time: DOMHighResTimeStamp, frame: any) → void
```

### Concrete Session Implementations

**XRSession wrapper:**
```
XRSessionAdapter implements Session {
  requestFrame = xrSession.requestAnimationFrame
  getCameras   = (frame) → mapXRViewsToCameras(frame, xrSession, xrLayer)
  getFramebuffer = () → xrLayer.framebuffer
  end          = () → xrSession.end()
}
```

**Desktop session:**
```
DesktopSessionAdapter implements Session {
  requestFrame = window.requestAnimationFrame
  getCameras   = () → [buildDesktopCamera(canvas, eye, target)]
  getFramebuffer = () → null  // draw to canvas directly
  end          = () → { /* cancel animation frame */ }
}
```

**Recorded playback session:**
```
PlaybackSessionAdapter implements Session {
  private frames: RecordedFrame[]
  private frameIndex = 0
  requestFrame = (cb) → { setTimeout(() => cb(frame), 16); frameIndex++ }
  getCameras   = () → this.frames[this.frameIndex].cameras
  getFramebuffer = () → null
  end          = () → { this.frameIndex = 0 }
}
```

### The Frame Loop With Session Abstraction

```typescript
const runLoop = (session: Session, ctx: RenderContext, initialUniverse: Universe) => {
  let universe = initialUniverse

  const onFrame = (time: number, frame: any) => {
    // Input is now separate from session — see InputAdapter below
    // (session provides cameras; adapters provide events)

    const cameras = session.getCameras(frame)
    const framebuffer = session.getFramebuffer(frame)

    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer)
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    for (const camera of cameras) {
      gl.viewport(camera.viewport.x, camera.viewport.y,
                  camera.viewport.width, camera.viewport.height)
      render(ctx, universe, camera)
    }

    session.requestFrame(onFrame)
  }

  session.requestFrame(onFrame)
}
```

The loop doesn't know whether it's in XR or desktop. The `session` tells it
how to get frames. The renderer uses the cameras. The update function uses
the events. Each piece is isolated.

<!-- YOUR THOUGHTS: -->


---

## IV. The InputAdapter Abstraction

Covered in depth in `INPUT.md`, but here is where it fits architecturally:

```
InputAdapter = {
  // Called once per frame with hardware-specific frame data
  // Returns abstract events
  readEvents: (frame: any, inputSources: any) → AbstractInputEvent[]
}
```

Multiple adapters can run simultaneously. Their outputs are merged:

```
const allAdapters: InputAdapter[] = [
  new XRHandAdapter(referenceSpace),
  new KeyboardAdapter(document),
  // ... future: MouseAdapter, ControllerAdapter
]

const events: AbstractInputEvent[] = allAdapters.flatMap(
  adapter => adapter.readEvents(frame, session.inputSources)
)
```

And then:
```
for (const event of events) {
  universe = update(universe, event)
}
```

The update function receives `AbstractInputEvent[]`. It is completely unaware
of hardware. Adding a new input device is: write one new adapter. Everything
else is unchanged.

<!-- YOUR THOUGHTS: -->


---

## V. The Capability Pattern — Formalized

Throughout these documents, "capability" has been used informally. Here it is
as a formal design principle.

### The Problem It Solves

Functions need resources to do their work: `gl` to render, `session` to query
XR, `referenceSpace` to get poses. The naive approach passes these as parameters
to every function that needs them. With many resources, every call site
becomes unwieldy.

The alternative (global variables) hides dependencies and makes testing
impossible. You can't test a function that secretly depends on a global.

The capability pattern: collect related resources into a typed record. Each
record type represents a PROVEN STATE of initialization. Functions declare
which capability record they need. They receive it as a parameter. Only one
parameter per group of related resources.

### Capability Records for Manas

```
RenderContext = {
  // Capability: I can draw things
  gl: WebGL2RenderingContext
  program: WebGLProgram
  uniformLocations: UniformLocations
  buffers: BufferRegistry
  vaos: VAORegistry
  geometryRegistry: GeometryRegistry
}

XRContext = {
  // Capability: I can read XR hardware
  session: XRSession
  referenceSpace: XRReferenceSpace
  xrLayer: XRWebGLLayer
}

AppContext = {
  // The whole initialized application
  renderContext: RenderContext
  xrContext: XRContext
  session: Session       // the abstract session
  adapters: InputAdapter[]
}
```

Functions declare their needs via their parameter types:
- A function that only renders: takes `(RenderContext, Universe, Camera)`
- A function that only reads XR: takes `(XRContext, frame)`
- A function that does everything: takes `(AppContext, ...)`

The type signature is a complete declaration of dependencies. Nothing is hidden.

<!-- YOUR THOUGHTS: -->


---

## VI. The Reader Pattern — Threading Context Without Pain

When many functions in a call chain need the same context, passing it through
every intermediate function is verbose. The Reader pattern (from FP) addresses
this.

A Reader is a function that takes a context and produces a value:
```
Reader<Context, A> = (context: Context) → A
```

If every function in a chain returns a Reader, you can compose them without
threading the context manually:

```typescript
// Instead of:
const result = f(ctx, g(ctx, h(ctx, x)))

// With Reader pattern:
const computation = pipe(
  h(x),          // Reader<Ctx, B>
  R.chain(g),    // Reader<Ctx, C>
  R.chain(f),    // Reader<Ctx, D>
)
const result = computation(ctx)  // provide context once, at the end
```

In fp-ts, `Reader<R, A>` is exactly this. `ReaderTaskEither<R, E, A>` adds
async and error handling. This is how you thread `gl` through an entire
rendering pipeline without passing it explicitly to each function.

This is the functional programming alternative to dependency injection
frameworks. The context is a first-class value, explicitly threaded but
without ceremony at each call site.

You don't need this immediately. But knowing it exists tells you: the verbosity
of passing `gl` everywhere has a known solution. It's not a flaw in FP;
it's a solved problem in FP.

<!-- YOUR THOUGHTS: -->


---

## VII. How the Abstractions Compose

Here is the complete picture of how all abstractions fit together:

```
                    ┌─────────────────────────────────┐
                    │         FRAME LOOP               │
                    │  session.requestFrame(onFrame)   │
                    └────────────┬────────────────────-┘
                                 │
                    ┌────────────▼────────────────────┐
                    │         INPUT PHASE              │
                    │  adapters[].readEvents(frame)    │
                    │  → AbstractInputEvent[]          │
                    └────────────┬────────────────────-┘
                                 │
                    ┌────────────▼────────────────────┐
                    │         UPDATE PHASE             │
                    │  events.reduce(update, universe) │
                    │  → new Universe                  │
                    └────────────┬────────────────────-┘
                                 │
                    ┌────────────▼────────────────────┐
                    │         RENDER PHASE             │
                    │  session.getCameras(frame)       │
                    │  → Camera[]                      │
                    │  cameras.forEach(render(ctx, u)) │
                    └─────────────────────────────────-┘
```

Each phase uses one abstraction:
- Frame loop: `Session` (provides timing and cameras)
- Input: `InputAdapter[]` (provides events from hardware)
- Update: pure function (no abstraction needed — it's pure)
- Render: `Camera` (abstract view specification) + `RenderContext` (GPU capabilities)

The Universe flows through all phases. It is the only thing that connects them.

### Extension Points — What You Add Later Without Touching the Core

| What you add | Where it goes | What doesn't change |
|---|---|---|
| New input device (joystick) | New InputAdapter | update(), render(), session |
| Spectator view | New Session (DesktopSession) | update(), adapters, render |
| New gesture (two-hand scale) | Extend XRHandAdapter output | render(), session |
| New entity type (document) | New Entity variant, new render case | adapters, session |
| Multiple users | Multiple input sources, merged events | render(), session abstraction |
| Recorded playback | New Session (PlaybackSession) | everything else |
| New rendering backend (WebGPU) | New RenderContext, new render() | update(), session, adapters |

The abstractions define the extension points. Adding a feature that isn't
on this list means the abstraction boundaries need revision. This is normal
and healthy — as you build, you discover the boundaries you actually need.

<!-- YOUR THOUGHTS: -->

---

*Comment anywhere. The extension table is especially worth annotating — what
features do you imagine adding? Do the abstractions support them?*
