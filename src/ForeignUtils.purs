module ForeignUtils where

import Prelude

import Data.Nullable (Nullable)
import Effect (Effect)


foreign import data Float32Array :: Type
foreign import float32Array :: forall a. a -> Float32Array

foreign import data Uint16Array :: Type
foreign import uint16Array :: forall a. a -> Uint16Array

foreign import getAt :: Float32Array -> Int -> Effect Number

foreign import setAt :: Float32Array -> Int -> Number -> Effect Unit

foreign import copyInto :: Float32Array -> Float32Array -> Int -> Effect Unit

foreign import subarray :: Float32Array -> Int -> Int -> Effect Float32Array

foreign import get3DDistance :: Float32Array -> Float32Array -> Effect Number

foreign import get3DDistanceFromMatrix :: Float32Array -> Float32Array -> Number

foreign import toArray :: Float32Array -> Array Number

foreign import multiplyMatrix4x4 :: Float32Array -> Float32Array -> Float32Array

foreign import sub3 :: Float32Array -> Float32Array -> Float32Array

foreign import dot3 :: Float32Array -> Float32Array -> Number

foreign import cross3 :: Float32Array -> Float32Array -> Float32Array

foreign import normalize3 :: Float32Array -> Float32Array

foreign import rayTriangleIntersect 
    :: { origin :: Float32Array, direction :: Float32Array } 
    -> Float32Array 
    -> Float32Array 
    -> Float32Array 
    -> Nullable Number

foreign import transformPoint3 :: Float32Array -> Float32Array -> Float32Array

foreign import translationMatrix4x4 :: Float32Array -> Float32Array

foreign import getTranslationFromMatrix :: Float32Array -> Float32Array

foreign import midpoint3 :: Float32Array -> Float32Array -> Float32Array

foreign import add3 :: Float32Array -> Float32Array -> Float32Array

foreign import getScaleFromMatrix :: Float32Array -> Number

foreign import axisAngleRotationMatrix :: Float32Array -> Number -> Number -> Float32Array
