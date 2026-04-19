module Math
  ( Vec3
  , vec3
  , zero
  , add
  , sub
  , scale
  , negate
  , dot
  , length
  , distance
  , cross
  , normalize
  , midpoint
  , toFloat32Array
  ) where

import Prelude hiding (add, sub, zero, negate)

import Data.Maybe (Maybe(..))
import Data.Number (sqrt)
import Primitives (Float32Array, float32Array)

newtype Vec3 = Vec3 Float32Array

vec3 :: Number -> Number -> Number -> Vec3
vec3 x y z = Vec3 (float32Array [x, y, z])

zero :: Vec3
zero = vec3 0.0 0.0 0.0

foreign import addImpl :: Float32Array -> Float32Array -> Float32Array
foreign import subImpl :: Float32Array -> Float32Array -> Float32Array
foreign import scaleImpl :: Number -> Float32Array -> Float32Array
foreign import dotImpl :: Float32Array -> Float32Array -> Number
foreign import crossImpl :: Float32Array -> Float32Array -> Float32Array

add :: Vec3 -> Vec3 -> Vec3
add (Vec3 a) (Vec3 b) = Vec3 (addImpl a b)

sub :: Vec3 -> Vec3 -> Vec3
sub (Vec3 a) (Vec3 b) = Vec3 (subImpl a b)

scale :: Number -> Vec3 -> Vec3
scale k (Vec3 v) = Vec3 (scaleImpl k v)

negate :: Vec3 -> Vec3
negate = sub zero

dot :: Vec3 -> Vec3 -> Number
dot (Vec3 a) (Vec3 b) = dotImpl a b

length :: Vec3 -> Number
length v = sqrt (dot v v)

distance :: Vec3 -> Vec3 -> Number
distance a b = length (sub a b)

cross :: Vec3 -> Vec3 -> Vec3
cross (Vec3 a) (Vec3 b) = Vec3 (crossImpl a b)

normalize :: Vec3 -> Maybe Vec3
normalize v =
  let len = length v
  in if len == 0.0
       then Nothing
       else Just (scale (1.0 / len) v)

midpoint :: Vec3 -> Vec3 -> Vec3
midpoint a b = scale 0.5 (add a b)

toFloat32Array :: Vec3 -> Float32Array
toFloat32Array (Vec3 arr) = arr
