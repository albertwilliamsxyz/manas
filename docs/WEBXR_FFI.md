# PureScript, WebXR, and WebGL2: Learning Summary

This document serves as a summary of the key concepts, architectural decisions, and required knowledge mapping for building a high-performance WebXR and WebGL2 engine from scratch using PureScript.

## 1. PureScript Fundamentals

### 1.1 Core Philosophy
*   **Strongly Typed & Inferred:** PureScript catches errors at compile time. Types like `String -> Effect Unit` explicitly document what a function requires and what it produces.
*   **Strict Evaluation:** Unlike Haskell, PureScript is strictly evaluated (like JavaScript). This makes reasoning about performance and memory usage much easier, which is critical for real-time graphics.
*   **Purely Functional:** Functions must return the exact same output for the same input and cannot have side effects (changing global state, writing to the DOM).
*   **Explicit Effects:** Any side effect is explicitly wrapped in the type system.
    *   `Effect a`: A synchronous side effect (e.g., printing to console `Main :: Effect Unit`, reading a ref).
    *   `Aff a`: An asynchronous side effect (e.g., a network request, a JavaScript Promise).

### 1.2 The Meaning of "Effect"
In functional jargon, an **Effect** is a side-effect (an action). An **Event** is a trigger in time (like a mouse click). PureScript forces functions that interact with the real world (DOM manipulation, logging) to return an `Effect` type, actively warning the compiler that this function is not "pure."

## 2. Functional Reactive Programming (FRP) & WebXR

FRP is a paradigm that describes changing state over time natively, rather than through manual event listeners.
*   **Events (Streams):** Discrete occurrences (a button click, a trigger pull).
*   **Behaviors (Signals):** Values that change continuously (headset rotation, hand position).

### The Reality of FRP for VR
**Theory:** FRP is mathematically perfect for VR because it easily describes complex continuous data streams without messy state synchronization bugs.
**Practice (The Catch):** Building a 90 FPS WebXR engine in strict FRP generates too many intermediate allocations (garbage). WebXR requires high performance and low garbage collection overhead to prevent motion sickness. While libraries like `Hareactive` exist for UI, for the critical render loop of a 3D engine, pure FRP is often too slow.

## 3. Performance Architecture: The Render Loop

To achieve 72-90 FPS on a standalone headset like the Meta Quest 3, we must abandon immutable paradigms inside the "hot path" (the `requestAnimationFrame` and `onXRFrame` loop).

### 3.1 The Garbage Collection Problem
Creating thousands of immutable vector objects every frame (e.g., updating 50 hand joints) will trigger the JavaScript Garbage Collector, causing stutter. 

### 3.2 The Solution
We must orchestrate high-level game logic in pure, immutable PureScript, but execute the low-level rendering logic mutably.
*   **State Refs:** Use `Effect.Ref` to hold the application state across frame boundaries.
*   **ArrayBuffers:** Use `purescript-arraybuffers` to manage `Float32Array` objects directly. We allocate these buffers *once* on startup and update their indices mutably every frame (e.g., filling them with WebXR joint poses).

## 4. Building the Engine from First Principles

To migrate the provided TypeScript WebGL2 logic, we must write our own Foreign Function Interfaces (FFI) for browser APIs that do not have maintained PureScript libraries.

### 4.1 Required Packages
*   `web-html` & `web-dom`: For `<canvas>` and DOM element interactions.
*   `effect`: For the `Effect` monad (synchronous side effects).
*   `aff` & `aff-promise`: For handling the asynchronous behavior of WebXR (`requestSession`, `requestReferenceSpace`).
*   `arraybuffer-types` & `arraybuffers`: For handling `Float32Array` and `Uint16Array` for WebGL buffers.
*   `refs`: For standard mutable state references (`Effect.Ref`).
*   `maybe` & `either`: For idiomatic error handling (e.g., `Either Error WebGL2RenderingContext`, `Maybe HTMLCanvasElement`).

### 4.2 Handling JavaScript FFI (Foreign Function Interface)
Because PureScript knows nothing about `WebGLRenderingContext` or `XRSystem`, we pair `.purs` files with `.js` files to create type-safe bridges.

#### The Opaque Type Pattern
1.  **Define the type in PureScript:** We declare a "black box" type.
    ```purescript
    foreign import data WebGL2RenderingContext :: Type
    ```
2.  **Implement in JavaScript:** We write JS that returns a zero-argument function to represent the `Effect` monad, managing `null` values using PureScript constructors (like `just` and `nothing`).
    ```javascript
    export const getContextImpl = (just) => (nothing) => (canvas) => {
      return () => { // The Effect wrapper
        const context = canvas.getContext('webgl2');
        return context ? just(context) : nothing;
      };
    };
    ```
3.  **Wrap cleanly in PureScript:**
    ```purescript
    foreign import getContextImpl :: (forall a. a -> Maybe a) -> (forall a. Maybe a) -> HTMLCanvasElement -> Effect (Maybe WebGL2RenderingContext)
    
    getContext :: HTMLCanvasElement -> Effect (Maybe WebGL2RenderingContext)
    getContext canvas = getContextImpl Just Nothing canvas
    ```
By following this pattern, we can safely map complex browser APIs like `gl.createShader`, `xr.requestSession`, and `gl.bufferData` into our pure, functional ecosystem.
