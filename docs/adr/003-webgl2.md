# ADR-003 — WebGL2 as the Graphics API

**Status:** Accepted  
**Date:** 2025  

---

## Context

The application renders 3D content (hand skeletons, models, drawings) directly in the browser without a scene-graph engine. The goal is to understand every step of the graphics pipeline from first principles, so a low-level API is preferable to a high-level framework like Three.js.

---

## Decision

Use the browser's **WebGL2** (`WebGL2RenderingContext`) directly — no wrapper library.

---

## What WebGL2 adds over WebGL1

| Feature | Why it matters here |
|---------|---------------------|
| `#version 300 es` GLSL | `in`/`out` variables instead of deprecated `attribute`/`varying` |
| Vertex Array Objects (VAO) | Bind vertex layout once, reuse per object — essential for the entity system |
| `gl.UNSIGNED_SHORT` indices | Skeleton edge list uses `Uint16Array` — WebGL1 only supported `UNSIGNED_BYTE` |
| `bufferSubData` with offset | Efficient per-frame hand joint update without reallocating the buffer |
| Integer textures, MRT, etc. | Headroom for future advanced rendering |

---

## Shader pipeline used

### Vertex shader (GLSL ES 3.00)

```glsl
#version 300 es
in vec3 a_position;
uniform mat4 u_projection;
uniform mat4 u_view;
uniform mat4 u_model;
void main() {
  gl_Position = u_projection * u_view * u_model * vec4(a_position, 1.0);
  gl_PointSize = 10.0;
}
```

- `a_position` — vertex attribute fed from the bound VAO/buffer.
- `u_model` — per-entity model matrix (position × rotation × scale).
- `u_view` — camera matrix, derived from `XRView.transform.inverse.matrix`.
- `u_projection` — per-eye perspective matrix, from `XRView.projectionMatrix`.
- `gl_PointSize` — renders joints as visible squares when using `gl.POINTS`.

### Fragment shader (GLSL ES 3.00)

```glsl
#version 300 es
precision highp float;
out vec4 outColor;
uniform vec4 u_color;
void main() {
  outColor = u_color;
}
```

Flat colour per draw call. The colour is set with `gl.uniform4fv(colorLocation, …)` before each `drawArrays` / `drawElements` call.

---

## VAO strategy

Each logical object (left hand, right hand, left skeleton, right skeleton, cube, …) has its own **Vertex Array Object**. A VAO stores:
1. Which buffer is bound to `ARRAY_BUFFER`.
2. The `vertexAttribPointer` layout.
3. (Optionally) which buffer is bound to `ELEMENT_ARRAY_BUFFER`.

Switching between objects is a single `gl.bindVertexArray(vao)` call — no redundant attribute setup per frame.

---

## Buffer update strategy

| Buffer type | Update frequency | WebGL usage hint |
|-------------|-----------------|-----------------|
| Cube vertices | Static (loaded once) | `gl.STATIC_DRAW` |
| Hand joint positions | Every XR frame | `gl.DYNAMIC_DRAW` + `gl.bufferSubData` |
| Skeleton edge indices | Static | `gl.STATIC_DRAW` |
| Drawing strokes | Grows as user draws | `gl.DYNAMIC_DRAW` + `gl.bufferData` (reallocate on append) |

**`bufferSubData` vs `bufferData`:** For hand joints the buffer size never changes (75 floats = 25 joints × 3 axes), so `bufferSubData` reuses the GPU allocation — significantly cheaper than `bufferData` which always triggers a reallocation.

---

## Draw modes

| Mode | Used for |
|------|---------|
| `gl.POINTS` | Joint spheres (hand tracking visualisation) |
| `gl.LINES` | Skeleton edges (via `drawElements` + index buffer) |
| `gl.TRIANGLES` | Cube faces |

---

## Rationale for no wrapper library (Three.js, Babylon.js, etc.)

1. **Understanding first:** The goal is for the code to reflect a personal understanding of every layer. Hiding WebGL behind a framework would hide the projection matrix derivation, the VAO lifecycle, and the uniform update model.
2. **Minimal surface area:** No framework means no framework bugs, no version lock, no opinionated scene graph that must be fought against.
3. **Future composability:** Each piece (shader, VAO, buffer update) is a pure function or a simple wrapper — trivial to replace or optimise individually.

---

## Consequences

- **Positive:** Full control over the rendering pipeline.
- **Positive:** Code directly mirrors the mathematical model (matrix multiplication → uniform → GPU).
- **Negative:** More boilerplate than a framework (shader compilation, program linking, VAO setup).
- **Negative:** No built-in asset loaders, lighting models, or material systems — all must be authored.
