module Primitives
  ( Float32Array
  , Uint16Array
  , Uint8Array
  , ArrayBufferView
  , float32Array
  , uint16Array
  , uint8Array
  , f32AsArrayBufferView
  , u16AsArrayBufferView
  , u8AsArrayBufferView
  , getAt
  , setAt
  , copyInto
  , subarray
  , toArray
  ) where

import Data.Unit (Unit)
import Effect (Effect)

foreign import data Float32Array :: Type
foreign import data Uint16Array :: Type
foreign import data Uint8Array :: Type
foreign import data ArrayBufferView :: Type

foreign import float32Array :: Array Number -> Float32Array
foreign import uint16Array :: Array Int -> Uint16Array
foreign import uint8Array :: Array Int -> Uint8Array

foreign import f32AsArrayBufferView :: Float32Array -> ArrayBufferView
foreign import u16AsArrayBufferView :: Uint16Array -> ArrayBufferView
foreign import u8AsArrayBufferView :: Uint8Array -> ArrayBufferView

foreign import getAt :: Float32Array -> Int -> Effect Number
foreign import setAt :: Float32Array -> Int -> Number -> Effect Unit

foreign import copyInto :: Float32Array -> Float32Array -> Int -> Effect Unit
foreign import subarray :: Float32Array -> Int -> Int -> Effect Float32Array

foreign import toArray :: Float32Array -> Array Number
