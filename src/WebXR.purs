module WebXR where

import Prelude

import Control.Promise (Promise, toAffE)
import Data.Nullable (Nullable)
import Effect (Effect)
import Effect.Aff (Aff)
import Web.HTML (Navigator)
import Web.HTML.Window (Window)
import WebGL2 (RenderingContext)

foreign import data XRSystem :: Type

foreign import getXRSystem :: Navigator -> Effect (Nullable XRSystem)

foreign import makeXRWebGL2CompatibleImpl :: RenderingContext -> Effect (Promise Unit)
makeXRWebGL2Compatible :: RenderingContext -> Aff Unit
makeXRWebGL2Compatible context = toAffE $ makeXRWebGL2CompatibleImpl context

foreign import isWebXRSessionModeSupportedImpl :: XRSystem -> String -> Effect (Promise Boolean)
isWebXRSessionModeSupported :: XRSystem -> String -> Aff Boolean
isWebXRSessionModeSupported xrSystem mode = toAffE $ isWebXRSessionModeSupportedImpl xrSystem mode


foreign import data XRSession :: Type
type RequestSessionOptions = { optionalFeatures :: Array String }

foreign import requestSessionImpl :: XRSystem -> String -> RequestSessionOptions -> Effect (Promise XRSession)
requestSession :: XRSystem -> String -> RequestSessionOptions -> Aff XRSession
requestSession xrSystem mode opts = toAffE $ requestSessionImpl xrSystem mode opts

foreign import data XRWebGLLayer :: Type

foreign import createXRWebGLLayer :: Window -> XRSession -> RenderingContext -> Effect XRWebGLLayer

foreign import updateRenderState :: forall r. XRSession -> Record r -> Effect Unit
