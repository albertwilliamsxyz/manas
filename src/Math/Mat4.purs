module Math.Mat4
  ( Mat4
  , identity
  , multiply
  , translation
  , translationOf
  , scale
  , scaleOf
  , axisAngleRotation
  , transformPoint
  , toFloat32Array
  , fromFloat32Array
  ) where

import Prelude hiding (identity)

import Math.Vec3 (Vec3)
import Math.Vec3 as Math.Vec3
import Primitives (Float32Array, float32Array)

newtype Mat4 = Mat4 Float32Array

identity :: Mat4
identity = Mat4 (float32Array
  [ 1.0, 0.0, 0.0, 0.0
  , 0.0, 1.0, 0.0, 0.0
  , 0.0, 0.0, 1.0, 0.0
  , 0.0, 0.0, 0.0, 1.0
  ])

scale :: Number -> Mat4
scale k = Mat4 (float32Array
  [ k,   0.0, 0.0, 0.0
  , 0.0, k,   0.0, 0.0
  , 0.0, 0.0, k,   0.0
  , 0.0, 0.0, 0.0, 1.0
  ])

foreign import multiplyImpl :: Float32Array -> Float32Array -> Float32Array
foreign import translationImpl :: Float32Array -> Float32Array
foreign import translationOfImpl :: Float32Array -> Float32Array
foreign import scaleOfImpl :: Float32Array -> Number
foreign import axisAngleRotationImpl :: Float32Array -> Number -> Number -> Float32Array
foreign import transformPointImpl :: Float32Array -> Float32Array -> Float32Array

multiply :: Mat4 -> Mat4 -> Mat4
multiply (Mat4 a) (Mat4 b) = Mat4 (multiplyImpl a b)

translation :: Vec3 -> Mat4
translation v = Mat4 (translationImpl (Math.Vec3.toFloat32Array v))

translationOf :: Mat4 -> Vec3
translationOf (Mat4 m) = Math.Vec3.fromFloat32Array (translationOfImpl m)

scaleOf :: Mat4 -> Number
scaleOf (Mat4 m) = scaleOfImpl m

axisAngleRotation :: Vec3 -> Number -> Number -> Mat4
axisAngleRotation axis cosAngle sinAngle =
  Mat4 (axisAngleRotationImpl (Math.Vec3.toFloat32Array axis) cosAngle sinAngle)

transformPoint :: Mat4 -> Vec3 -> Vec3
transformPoint (Mat4 m) v =
  Math.Vec3.fromFloat32Array (transformPointImpl m (Math.Vec3.toFloat32Array v))

toFloat32Array :: Mat4 -> Float32Array
toFloat32Array (Mat4 m) = m

fromFloat32Array :: Float32Array -> Mat4
fromFloat32Array = Mat4
