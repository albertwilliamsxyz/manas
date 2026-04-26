module WebXR
  ( makeXRWebGL2Compatible
  , isWebXRSessionModeSupported
  , requestSession
  , requestReferenceSpace
  ) where

import Prelude

import Control.Promise (toAffE)
import Effect.Aff (Aff)
import WebGL2.Raw (RenderingContext)
import WebXR.Raw as Raw


makeXRWebGL2Compatible :: RenderingContext -> Aff Unit
makeXRWebGL2Compatible context = toAffE $ Raw.makeXRWebGL2Compatible context

isWebXRSessionModeSupported :: Raw.XRSystem -> String -> Aff Boolean
isWebXRSessionModeSupported xrSystem mode = toAffE $ Raw.isWebXRSessionModeSupported xrSystem mode

requestSession :: Raw.XRSystem -> String -> Raw.RequestSessionOptions -> Aff Raw.XRSession
requestSession xrSystem mode opts = toAffE $ Raw.requestSession xrSystem mode opts

requestReferenceSpace :: Raw.XRSession -> String -> Aff Raw.ReferenceSpace
requestReferenceSpace session typ = toAffE $ Raw.requestReferenceSpace session typ
