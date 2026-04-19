module WebXR where

import Prelude

import Control.Promise (Promise, toAffE)
import Data.Nullable (Nullable)
import Effect (Effect)
import Effect.Aff (Aff)
import Web.HTML (Navigator)
import Web.HTML.Window (Window)
import WebGL2 (RenderingContext)
import Primitives as Primitives


foreign import data XRSystem :: Type

foreign import getXRSystem :: Navigator -> Effect (Nullable XRSystem)

foreign import makeXRWebGL2CompatibleImpl :: RenderingContext -> Effect (Promise Unit)
makeXRWebGL2Compatible :: RenderingContext -> Aff Unit
makeXRWebGL2Compatible context = toAffE $ makeXRWebGL2CompatibleImpl context

foreign import isWebXRSessionModeSupportedImpl :: XRSystem -> String -> Effect (Promise Boolean)
isWebXRSessionModeSupported :: XRSystem -> String -> Aff Boolean
isWebXRSessionModeSupported xrSystem mode = toAffE $ isWebXRSessionModeSupportedImpl xrSystem mode


foreign import data XRSession :: Type
type RequestSessionOptions = { requiredFeatures :: Array String }

foreign import requestSessionImpl :: XRSystem -> String -> RequestSessionOptions -> Effect (Promise XRSession)
requestSession :: XRSystem -> String -> RequestSessionOptions -> Aff XRSession
requestSession xrSystem mode opts = toAffE $ requestSessionImpl xrSystem mode opts

foreign import data XRWebGLLayer :: Type

foreign import createXRWebGLLayer :: Window -> XRSession -> RenderingContext -> Effect XRWebGLLayer

foreign import updateRenderState :: forall r. XRSession -> Record r -> Effect Unit

foreign import data ReferenceSpace :: Type

foreign import requestReferenceSpaceImpl :: XRSession -> String -> Effect (Promise ReferenceSpace)

requestReferenceSpace :: XRSession -> String -> Aff ReferenceSpace
requestReferenceSpace session typ = toAffE $ requestReferenceSpaceImpl session typ


foreign import data XRFrame :: Type
foreign import data XRViewerPose :: Type
foreign import data XRJointPose :: Type
foreign import data XRJointSpace :: Type

type XRFrameRequestCallback = Number -> XRFrame -> Effect Unit

foreign import getViewerPose 
  :: XRFrame -> ReferenceSpace -> Effect (Nullable XRViewerPose)

foreign import getJointPose 
  :: XRFrame -> XRJointSpace -> ReferenceSpace -> Effect (Nullable XRJointPose)

foreign import requestAnimationFrame :: XRSession -> XRFrameRequestCallback -> Effect Int


foreign import data XRInputSource :: Type
foreign import data XRHand :: Type

foreign import getInputSources :: XRSession -> Effect (Array XRInputSource)

foreign import getHand :: XRInputSource -> Effect (Nullable XRHand)

foreign import getHandedness :: XRInputSource -> Effect (Nullable String)

foreign import getHandJoints :: XRHand -> Effect (Array { name :: String, space :: XRJointSpace })

foreign import getJointPosition :: XRJointPose -> Effect Primitives.Float32Array

foreign import data XRView :: Type
type XRViewport = 
  { x :: Int
  , y :: Int
  , width :: Int
  , height :: Int 
  }

foreign import getViews :: XRViewerPose -> Effect (Array XRView)

foreign import getViewport :: XRWebGLLayer -> XRView -> Effect (Nullable XRViewport)


foreign import getProjectionMatrix :: XRView -> Effect Primitives.Float32Array

foreign import getViewMatrix :: XRView -> Effect Primitives.Float32Array

foreign import data XRFramebuffer :: Type
foreign import getFramebuffer :: XRWebGLLayer -> Effect XRFramebuffer

