module WebXR where

import Prelude

import Control.Promise (Promise, toAffE)
import Data.Nullable (Nullable)
import Data.Tuple (Tuple)
import Effect (Effect)
import Effect.Aff (Aff)
import Web.HTML (Navigator)
import Web.HTML.Window (Window)
import WebGL2 (RenderingContext)
import ForeignUtils as ForeignUtils


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

foreign import getHandJoints :: XRHand -> Effect (Array (Tuple String XRJointSpace))

foreign import getJointPosition :: XRJointPose -> Effect ForeignUtils.Float32Array
