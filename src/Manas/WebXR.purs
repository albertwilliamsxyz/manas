module Manas.WebXR
  ( XRSystem
  , XRSession
  , XRWebGLLayer
  , XRReferenceSpace
  , XRFrame
  , XRViewerPose
  , XRView
  , XRViewport
  , XRInputSource
  , XRHand
  , XRJointSpace
  , XRJointPose
  , getXRSystem
  , isSessionSupported
  , requestSession
  , createXRWebGLLayer
  , updateRenderState
  , requestReferenceSpace
  , requestAnimationFrame
  , getInputSources
  , getHand
  , getHandedness
  , getHandEntries
  , getJointPose
  , getJointPosePosition
  , getViewerPose
  , getViews
  , getViewProjectionMatrix
  , getViewTransformInverseMatrix
  , getViewport
  , getViewportDimensions
  , getFramebuffer
  ) where

import Prelude

import Effect (Effect)
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toMaybe)
import Manas.Graphics (WebGL2Context, WebGLFramebuffer)

foreign import data XRSystem :: Type
foreign import data XRSession :: Type
foreign import data XRWebGLLayer :: Type
foreign import data XRReferenceSpace :: Type
foreign import data XRFrame :: Type
foreign import data XRViewerPose :: Type
foreign import data XRView :: Type
foreign import data XRViewport :: Type
foreign import data XRInputSource :: Type
foreign import data XRHand :: Type
foreign import data XRJointSpace :: Type
foreign import data XRJointPose :: Type

foreign import getXRSystemImpl :: Effect (Nullable XRSystem)

getXRSystem :: Effect (Maybe XRSystem)
getXRSystem = map toMaybe getXRSystemImpl

foreign import isSessionSupported :: XRSystem -> String -> Effect Boolean

foreign import requestSession :: XRSystem -> String -> Effect XRSession

foreign import createXRWebGLLayer :: XRSession -> WebGL2Context -> Effect XRWebGLLayer

foreign import updateRenderState :: XRSession -> XRWebGLLayer -> Effect Unit

foreign import requestReferenceSpace :: XRSession -> String -> Effect XRReferenceSpace

foreign import requestAnimationFrame :: XRSession -> (Number -> XRFrame -> Effect Unit) -> Effect Unit

foreign import getInputSources :: XRSession -> Effect (Array XRInputSource)

foreign import getHandImpl :: XRInputSource -> Nullable XRHand

getHand :: XRInputSource -> Maybe XRHand
getHand = toMaybe <<< getHandImpl

foreign import getHandedness :: XRInputSource -> String

foreign import getHandEntries :: XRHand -> Effect (Array { jointName :: String, jointSpace :: XRJointSpace })

foreign import getJointPoseImpl :: XRFrame -> XRJointSpace -> XRReferenceSpace -> Effect (Nullable XRJointPose)

getJointPose :: XRFrame -> XRJointSpace -> XRReferenceSpace -> Effect (Maybe XRJointPose)
getJointPose frame js rs = map toMaybe (getJointPoseImpl frame js rs)

foreign import getJointPosePosition :: XRJointPose -> { x :: Number, y :: Number, z :: Number }

foreign import getViewerPoseImpl :: XRFrame -> XRReferenceSpace -> Effect (Nullable XRViewerPose)

getViewerPose :: XRFrame -> XRReferenceSpace -> Effect (Maybe XRViewerPose)
getViewerPose frame rs = map toMaybe (getViewerPoseImpl frame rs)

foreign import getViews :: XRViewerPose -> Array XRView

foreign import getViewProjectionMatrix :: XRView -> Array Number

foreign import getViewTransformInverseMatrix :: XRView -> Array Number

foreign import getViewportImpl :: XRWebGLLayer -> XRView -> Nullable XRViewport

getViewport :: XRWebGLLayer -> XRView -> Maybe XRViewport
getViewport layer view = toMaybe (getViewportImpl layer view)

foreign import getViewportDimensions :: XRViewport -> { x :: Int, y :: Int, width :: Int, height :: Int }

foreign import getFramebuffer :: XRWebGLLayer -> WebGLFramebuffer
