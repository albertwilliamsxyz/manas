---
name: Type honesty in math primitives
description: Functions operating on vectors/matrices must have types that reflect their actual domain (Vec3, Mat4x4), not raw Float32Array
type: feedback
---

Math functions like `sub3`, `add3`, `transformPoint3`, `get3DDistance`, `multiplyMatrix4x4` currently accept `Float32Array` — a lie. They don't accept *any* Float32Array, they accept vectors of specific dimensionality or matrices of specific shape.

**Why:** Albert identified that the FFI layer is dishonest about types. A `sub3` operates on Vec3, not Float32Array. A `multiplyMatrix4x4` operates on Mat4x4, not Float32Array. The naming tries to compensate (`3`, `4x4`) but the types don't enforce it.

**How to apply:** When working on math primitives, the PureScript interface should present honest types (Vec3, Vec4, Mat4x4, etc.) even if the JS implementation uses Float32Array underneath. The FFI boundary is where the conversion happens — newtypes over Float32Array give zero-cost type safety. Names should also be consistent: if the type is Vec3, you don't need `sub3` — you need `sub` on Vec3.
