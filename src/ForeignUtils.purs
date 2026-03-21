module ForeignUtils where

import Prelude

import Effect (Effect)


foreign import data Float32Array :: Type
foreign import float32Array :: forall a. a -> Float32Array

foreign import data Uint16Array :: Type
foreign import uint16Array :: forall a. a -> Uint16Array

foreign import getAt :: Float32Array -> Int -> Effect Number

foreign import setAt :: Float32Array -> Int -> Number -> Effect Unit

foreign import copyInto :: Float32Array -> Float32Array -> Int -> Effect Unit

