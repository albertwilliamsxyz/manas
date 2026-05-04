module Image
  ( loadImage
  ) where

import Prelude

import Control.Promise (Promise, toAffE)
import Effect (Effect)
import Effect.Aff (Aff)
import Web.HTML.HTMLImageElement (HTMLImageElement)


foreign import loadImageImpl :: String -> Effect (Promise HTMLImageElement)


loadImage :: String -> Aff HTMLImageElement
loadImage = toAffE <<< loadImageImpl
