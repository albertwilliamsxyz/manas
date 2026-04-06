---
name: Module structure preferences
description: FFI modules should have two flat sub-layers (raw binding + idiomatic PureScript), keep modules as flat as possible
type: feedback
---

FFI modules (WebGL2, WebXR) should have two sub-layers:
1. Raw FFI binding — flat, 1:1 with JS API, no opinions
2. PureScript-idiomatic layer — typed, syntactic sugar, Maybe instead of Nullable, Aff instead of Promise

**Why:** Albert wants base FFI modules as flat as possible. The raw binding is a faithful translation; the idiomatic layer adds convenience without hiding the underlying API.

**How to apply:** When working on FFI modules, keep the two layers visible (can be in the same file with comments, or separate modules). Don't mix binding code with convenience functions. WebXR already partially follows this with the Impl/wrapper pattern.
