---
name: Parse don't validate
description: Validate at construction boundaries, never at operations. Smart constructors carry the proof. Internal function signatures stay simple and total.
type: feedback
---

Validate once when data enters the system (FFI, XR frames, user input), construct domain types (Vec3, Mat4) at that boundary. After construction, the type carries the guarantee — internal functions don't re-validate.

**Why:** Albert identified the tension: adding runtime validation inside `sub` would either pollute the return type (Maybe) or lie (exceptions). The resolution: validation at construction means `sub :: Vec3 -> Vec3 -> Vec3` is genuinely total — no hidden cases, no compromise. The simple signature IS the correct signature.

**How to apply:** Never add validation inside pure operations on domain types. If you feel the need to validate inside an operation, it means the type isn't carrying enough information — fix the type/constructor, not the operation. Identify boundaries where raw data enters (FFI, XR, WebGL) and convert to domain types there.
