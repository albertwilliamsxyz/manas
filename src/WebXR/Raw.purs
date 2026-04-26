module WebXR.Raw where

import Prelude

import Control.Promise (Promise)
import Data.Nullable (Nullable)
import Effect (Effect)
import Web.HTML (Navigator)
import Web.HTML.Window (Window)
import WebGL2.Raw (RenderingContext, Framebuffer)
import Primitives as Primitives


foreign import data XRSystem :: Type
foreign import getXRSystem :: Navigator -> Effect (Nullable XRSystem)

foreign import makeXRWebGL2Compatible :: RenderingContext -> Effect (Promise Unit)
foreign import isWebXRSessionModeSupported :: XRSystem -> String -> Effect (Promise Boolean)


foreign import data XRSession :: Type
type RequestSessionOptions = { requiredFeatures :: Array String }

foreign import requestSession :: XRSystem -> String -> RequestSessionOptions -> Effect (Promise XRSession)


foreign import data XRWebGLLayer :: Type
foreign import createXRWebGLLayer :: Window -> XRSession -> RenderingContext -> Effect XRWebGLLayer
foreign import updateRenderState :: forall r. XRSession -> Record r -> Effect Unit


foreign import data ReferenceSpace :: Type
foreign import requestReferenceSpace :: XRSession -> String -> Effect (Promise ReferenceSpace)


foreign import data XRFrame :: Type
foreign import data XRViewerPose :: Type
foreign import data XRJointPose :: Type
foreign import data XRJointSpace :: Type

type XRFrameRequestCallback = Number -> XRFrame -> Effect Unit

foreign import getViewerPose :: XRFrame -> ReferenceSpace -> Effect (Nullable XRViewerPose)
foreign import getJointPose :: XRFrame -> XRJointSpace -> ReferenceSpace -> Effect (Nullable XRJointPose)
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

foreign import getFramebuffer :: XRWebGLLayer -> Effect Framebuffer
