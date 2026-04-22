module Math.Geometry
  ( rayTriangleIntersect
  ) where

import Prelude

import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toMaybe)
import Math.Vec3 (Vec3)
import Math.Vec3 as Math.Vec3
import Primitives (Float32Array)

foreign import rayTriangleIntersectImpl
    :: { origin :: Float32Array, direction :: Float32Array }
    -> Float32Array
    -> Float32Array
    -> Float32Array
    -> Nullable Number

rayTriangleIntersect
    :: { origin :: Vec3, direction :: Vec3 }
    -> Vec3
    -> Vec3
    -> Vec3
    -> Maybe Number
rayTriangleIntersect ray v0 v1 v2 = toMaybe $ rayTriangleIntersectImpl
    { origin: Math.Vec3.toFloat32Array ray.origin
    , direction: Math.Vec3.toFloat32Array ray.direction
    }
    (Math.Vec3.toFloat32Array v0)
    (Math.Vec3.toFloat32Array v1)
    (Math.Vec3.toFloat32Array v2)
