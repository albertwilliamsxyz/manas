# ADR-004 — WebXR for Immersive AR/VR

**Status:** Accepted  
**Date:** 2025  

---

## Context

The application is an immersive experience that must run on consumer AR/VR devices accessible through a standard browser (e.g. Meta Quest browsers). The platform standard for browser-based XR is **WebXR Device API**.

---

## Decision

Use the **WebXR Device API** (`navigator.xr`) as the sole interface to XR hardware.

---

## Core concepts

### Session modes

| Mode | Meaning |
|------|---------|
| `'immersive-ar'` | Device camera passthrough; real world visible; used here |
| `'immersive-vr'` | Fully synthetic environment |
| `'inline'` | Preview in a regular `<canvas>`, no headset required |

```typescript
const isSupported = await xr.isSessionSupported('immersive-ar')
const xrSession  = await xr.requestSession('immersive-ar', {
  optionalFeatures: ['hit-test', 'hand-tracking']
})
```

`optionalFeatures` — the session starts even if the device doesn't support those features; their absence is handled gracefully.

---

### Reference spaces

```typescript
const referenceSpace = await xrSession.requestReferenceSpace('local')
```

| Space | Origin | Use case |
|-------|--------|---------|
| `'local'` | Where the user started the session | Default for room-scale AR |
| `'local-floor'` | Floor level at session start | Standing experiences |
| `'bounded-floor'` | Pre-mapped room boundary | Room-scale VR |
| `'unbounded'` | World-scale tracking | Outdoor AR |

`'local'` is correct for this app — anchored to the user's starting position.

---

### Frame loop

```typescript
const onXRFrame: XRFrameRequestCallback = (time, frame) => {
  // 1. Read hand poses
  // 2. Update GPU buffers
  // 3. Read viewer pose
  // 4. Bind framebuffer
  // 5. Draw per-eye
  xrSession.requestAnimationFrame(onXRFrame)   // schedule next frame
}
xrSession.requestAnimationFrame(onXRFrame)     // kick off
```

`XRSession.requestAnimationFrame` is analogous to `window.requestAnimationFrame` but is driven by the headset's display refresh rate (typically 72–120 Hz).

---

### Per-eye rendering

```typescript
const pose = frame.getViewerPose(referenceSpace)
for (const view of pose.views) {
  const viewport = xrGLLayer.getViewport(view)
  gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height)

  // These come directly from the XR runtime — no manual projection math needed per frame
  gl.uniformMatrix4fv(projectionLocation, false, view.projectionMatrix)
  gl.uniformMatrix4fv(viewLocation, false, view.transform.inverse.matrix)

  // … draw calls …
}
```

- `view.projectionMatrix` — asymmetric perspective matrix pre-computed by the XR runtime to match the physical lens geometry of the headset.
- `view.transform.inverse.matrix` — the view matrix (world → eye). The `inverse` is used because the transform gives eye → world; the view matrix goes the other direction.

---

### Hand tracking

```typescript
for (const inputSource of xrSession.inputSources) {
  if (!inputSource.hand) continue     // not a hand (could be a controller)

  for (const [jointName, jointSpace] of inputSource.hand) {
    const jointPose = frame.getJointPose?.(jointSpace, referenceSpace)
    if (!jointPose) continue           // joint not tracked this frame

    const idx = HAND_JOINT_INDICES_BY_NAME[jointName]
    vertices[idx * 3]     = jointPose.transform.position.x
    vertices[idx * 3 + 1] = jointPose.transform.position.y
    vertices[idx * 3 + 2] = jointPose.transform.position.z
  }
}
```

The WebXR Hand Input API provides **25 joints per hand** (wrist + 4 joints × 5 fingers + finger tips). Each joint is a `XRJointSpace` whose pose can be queried per frame. Positions are in the reference space coordinate system.

#### Joint index map

```
Wrist: 0
Thumb:  metacarpal(1) → proximal(2) → distal(3) → tip(4)
Index:  metacarpal(5) → proximal(6) → intermediate(7) → distal(8) → tip(9)
Middle: metacarpal(10) → proximal(11) → intermediate(12) → distal(13) → tip(14)
Ring:   metacarpal(15) → proximal(16) → intermediate(17) → distal(18) → tip(19)
Pinky:  metacarpal(20) → proximal(21) → intermediate(22) → distal(23) → tip(24)
```

---

### XRWebGLLayer

```typescript
const xrGLLayer = new XRWebGLLayer(xrSession, gl)
xrSession.updateRenderState({ baseLayer: xrGLLayer })
```

Connects the WebGL2 context to the XR session so the XR runtime knows where to composite the rendered output. `gl.makeXRCompatible()` must be called on the context before creating the layer.

---

### `gl.makeXRCompatible()`

```typescript
await gl.makeXRCompatible()
```

Signals to the browser that this WebGL2 context will be used with WebXR. On some platforms this triggers context re-creation, which is why it must be awaited before the session starts.

---

## HTTPS requirement

WebXR only works over **HTTPS** (or `localhost`). The dev server uses `@vitejs/plugin-basic-ssl` to provide a self-signed certificate for local development on a device (see ADR-007).

---

## Consequences

- **Positive:** Single standard API runs on Meta Quest, HoloLens, and any future WebXR-capable browser.
- **Positive:** XR runtime supplies lens-corrected projection matrices — no need to derive them manually per frame.
- **Negative:** Requires HTTPS even in development (mitigated by plugin-basic-ssl).
- **Negative:** `navigator.xr` availability varies; must check `isSessionSupported` before attempting to start.
- **Negative:** Hand tracking is an optional feature — graceful degradation required when not available.
