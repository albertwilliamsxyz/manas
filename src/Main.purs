module Main where

import Prelude

import Data.Array (length)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Console (log, error)

import Manas.Constants
  ( baseNumberOfDimensions
  , numberOfJointsPerHand
  , numberOfHandJointDimensions
  , handSkeletonByJointIndices
  , cubeVertices
  , indexFingerTip
  , thumbTip
  , lookupJointIndex
  )
import Manas.Shaders (vertexShaderSource, fragmentShaderSource)
import Manas.Graphics as G
import Manas.WebXR as XR

identityMatrix :: Array Number
identityMatrix =
  [ 1.0, 0.0, 0.0, 0.0
  , 0.0, 1.0, 0.0, 0.0
  , 0.0, 0.0, 1.0, 0.0
  , 0.0, 0.0, 0.0, 1.0
  ]

defaultColor :: Array Number
defaultColor = [ 0.0, 0.8, 0.0, 1.0 ]

pinchThreshold :: Number
pinchThreshold = 0.02

-- | Create and compile a shader, returning Nothing on failure
createAndCompileShader
  :: G.WebGL2Context
  -> Int
  -> String
  -> Effect (Maybe G.WebGLShader)
createAndCompileShader gl shaderType source = do
  mShader <- G.createShader gl shaderType
  case mShader of
    Nothing -> do
      error "Unable to create shader"
      pure Nothing
    Just shader -> do
      G.shaderSource gl shader source
      G.compileShader gl shader
      compiled <- G.getShaderParameter gl shader
      if compiled
        then pure (Just shader)
        else do
          errMsg <- G.getShaderInfoLog gl shader
          error ("Shader compilation error: " <> errMsg)
          G.deleteShader gl shader
          pure Nothing

-- | Create and link a program from vertex and fragment shaders
createAndLinkProgram
  :: G.WebGL2Context
  -> G.WebGLShader
  -> G.WebGLShader
  -> Effect (Maybe G.WebGLProgram)
createAndLinkProgram gl vertexShader fragmentShader = do
  mProgram <- G.createProgram gl
  case mProgram of
    Nothing -> do
      error "Unable to create program"
      pure Nothing
    Just program -> do
      G.attachShader gl program vertexShader
      G.attachShader gl program fragmentShader
      G.linkProgram gl program
      linked <- G.getProgramParameter gl program
      if linked
        then do
          G.useProgram gl program
          pure (Just program)
        else do
          errMsg <- G.getProgramInfoLog gl program
          error ("Program link error: " <> errMsg)
          G.deleteProgram gl program
          pure Nothing

-- | Set up all uniform locations and return them
type UniformLocations =
  { projection :: G.WebGLUniformLocation
  , view :: G.WebGLUniformLocation
  , model :: G.WebGLUniformLocation
  , color :: G.WebGLUniformLocation
  }

setupUniforms
  :: G.WebGL2Context
  -> G.WebGLProgram
  -> Effect (Maybe UniformLocations)
setupUniforms gl program = do
  mProj <- G.getUniformLocation gl program "u_projection"
  mView <- G.getUniformLocation gl program "u_view"
  mModel <- G.getUniformLocation gl program "u_model"
  mColor <- G.getUniformLocation gl program "u_color"
  case mProj, mView, mModel, mColor of
    Just proj, Just view, Just model, Just color -> do
      G.uniformMatrix4fv gl proj identityMatrix
      G.uniformMatrix4fv gl view identityMatrix
      G.uniformMatrix4fv gl model identityMatrix
      G.uniform4fv gl color defaultColor
      pure (Just { projection: proj, view, model, color })
    _, _, _, _ -> do
      error "Unable to get uniform locations"
      pure Nothing

-- | Set up a vertex array object with buffer for static data
setupStaticVAO
  :: G.WebGL2Context
  -> Int
  -> Array Number
  -> Effect { vao :: G.WebGLVertexArray, buffer :: G.WebGLBuffer }
setupStaticVAO gl posLoc vertices = do
  vao <- G.createVertexArray gl
  buffer <- G.createBuffer gl
  G.bindVertexArray gl vao
  G.bindArrayBuffer gl buffer
  G.bufferDataStaticDraw gl vertices
  G.vertexAttribPointer gl posLoc baseNumberOfDimensions
  G.enableVertexAttribArray gl posLoc
  pure { vao, buffer }

-- | Set up a vertex array object with dynamic buffer (for hand tracking)
setupDynamicVAO
  :: G.WebGL2Context
  -> Int
  -> Effect { vao :: G.WebGLVertexArray, buffer :: G.WebGLBuffer }
setupDynamicVAO gl posLoc = do
  vao <- G.createVertexArray gl
  buffer <- G.createBuffer gl
  G.bindVertexArray gl vao
  G.bindArrayBuffer gl buffer
  G.bufferDataDynamicDraw gl numberOfHandJointDimensions
  G.vertexAttribPointer gl posLoc baseNumberOfDimensions
  G.enableVertexAttribArray gl posLoc
  pure { vao, buffer }

-- | Set up skeleton VAO sharing the hand buffer
setupSkeletonVAO
  :: G.WebGL2Context
  -> Int
  -> G.WebGLBuffer
  -> G.WebGLBuffer
  -> Effect G.WebGLVertexArray
setupSkeletonVAO gl posLoc handBuffer indexBuffer = do
  vao <- G.createVertexArray gl
  G.bindVertexArray gl vao
  G.bindArrayBuffer gl handBuffer
  G.vertexAttribPointer gl posLoc baseNumberOfDimensions
  G.enableVertexAttribArray gl posLoc
  G.bindElementArrayBuffer gl indexBuffer
  pure vao

-- | Compute Euclidean distance between two 3D points given as flat array indices
distance3D :: Array Number -> Int -> Int -> Number
distance3D = distanceImpl

foreign import distanceImpl :: Array Number -> Int -> Int -> Number

-- | Process hand tracking data for a single frame
processHandInput
  :: XR.XRFrame
  -> XR.XRReferenceSpace
  -> Array XR.XRInputSource
  -> Effect { leftVertices :: Array Number, rightVertices :: Array Number }
processHandInput frame refSpace sources = processHandInputImpl frame refSpace sources

foreign import processHandInputImpl
  :: XR.XRFrame
  -> XR.XRReferenceSpace
  -> Array XR.XRInputSource
  -> Effect { leftVertices :: Array Number, rightVertices :: Array Number }

-- | Render a single XR frame
renderFrame
  :: G.WebGL2Context
  -> UniformLocations
  -> XR.XRWebGLLayer
  -> { cubeVAO :: G.WebGLVertexArray
     , leftHandVAO :: G.WebGLVertexArray
     , leftSkeletonVAO :: G.WebGLVertexArray
     , rightHandVAO :: G.WebGLVertexArray
     , rightSkeletonVAO :: G.WebGLVertexArray
     }
  -> XR.XRViewerPose
  -> Effect Unit
renderFrame gl uniforms xrLayer vaos pose = do
  G.bindFramebuffer gl (XR.getFramebuffer xrLayer)
  G.clearColor gl 0.0 0.0 0.0 0.3
  G.clear gl
  let views = XR.getViews pose
  renderViews gl uniforms xrLayer vaos views

renderViews
  :: G.WebGL2Context
  -> UniformLocations
  -> XR.XRWebGLLayer
  -> { cubeVAO :: G.WebGLVertexArray
     , leftHandVAO :: G.WebGLVertexArray
     , leftSkeletonVAO :: G.WebGLVertexArray
     , rightHandVAO :: G.WebGLVertexArray
     , rightSkeletonVAO :: G.WebGLVertexArray
     }
  -> Array XR.XRView
  -> Effect Unit
renderViews _ _ _ _ [] = pure unit
renderViews gl uniforms xrLayer vaos views = renderViewsImpl gl uniforms xrLayer vaos views

foreign import renderViewsImpl
  :: G.WebGL2Context
  -> UniformLocations
  -> XR.XRWebGLLayer
  -> { cubeVAO :: G.WebGLVertexArray
     , leftHandVAO :: G.WebGLVertexArray
     , leftSkeletonVAO :: G.WebGLVertexArray
     , rightHandVAO :: G.WebGLVertexArray
     , rightSkeletonVAO :: G.WebGLVertexArray
     }
  -> Array XR.XRView
  -> Effect Unit

-- | Set up click handler on the start button
foreign import setupStartButton :: String -> Effect Unit -> Effect Unit

-- | Main application entry point
main :: Effect Unit
main = do
  log "Starting application"

  mGl <- G.getWebGL2Context "application"
  case mGl of
    Nothing -> error "Application canvas not found or WebGL2 not supported"
    Just gl -> do
      G.makeXRCompatible gl

      mXR <- XR.getXRSystem
      case mXR of
        Nothing -> error "WebXR not supported"
        Just xr -> do
          supported <- XR.isSessionSupported xr "immersive-ar"
          if not supported
            then error "Immersive AR not supported"
            else do
              mVS <- createAndCompileShader gl G.vertexShaderType vertexShaderSource
              case mVS of
                Nothing -> error "Failed to compile vertex shader"
                Just vs -> do
                  mFS <- createAndCompileShader gl G.fragmentShaderType fragmentShaderSource
                  case mFS of
                    Nothing -> error "Failed to compile fragment shader"
                    Just fs -> do
                      G.enableDepthTest gl
                      mProg <- createAndLinkProgram gl vs fs
                      case mProg of
                        Nothing -> error "Failed to link program"
                        Just program -> do
                          posLoc <- G.getAttribLocation gl program "a_position"

                          mUniforms <- setupUniforms gl program
                          case mUniforms of
                            Nothing -> error "Failed to set up uniforms"
                            Just uniforms -> do
                              -- Set up cube
                              cube <- setupStaticVAO gl posLoc cubeVertices

                              -- Set up hand skeleton index buffer
                              indexBuf <- G.createBuffer gl
                              G.bindElementArrayBuffer gl indexBuf
                              G.bufferDataElementStaticDraw gl handSkeletonByJointIndices

                              -- Set up hands
                              leftHand <- setupDynamicVAO gl posLoc
                              leftSkeleton <- setupSkeletonVAO gl posLoc leftHand.buffer indexBuf
                              rightHand <- setupDynamicVAO gl posLoc
                              rightSkeleton <- setupSkeletonVAO gl posLoc rightHand.buffer indexBuf

                              log "Program loaded successfully, waiting for user to start the experience"

                              let vaos =
                                    { cubeVAO: cube.vao
                                    , leftHandVAO: leftHand.vao
                                    , leftSkeletonVAO: leftSkeleton
                                    , rightHandVAO: rightHand.vao
                                    , rightSkeletonVAO: rightSkeleton
                                    }

                              setupStartButton "start-experience" do
                                startXRSession gl xr uniforms xrLayer vaos leftHand rightHand
                                where
                                  xrLayer = unit -- placeholder, created in startXRSession

startXRSession
  :: G.WebGL2Context
  -> XR.XRSystem
  -> UniformLocations
  -> Unit
  -> { cubeVAO :: G.WebGLVertexArray
     , leftHandVAO :: G.WebGLVertexArray
     , leftSkeletonVAO :: G.WebGLVertexArray
     , rightHandVAO :: G.WebGLVertexArray
     , rightSkeletonVAO :: G.WebGLVertexArray
     }
  -> { vao :: G.WebGLVertexArray, buffer :: G.WebGLBuffer }
  -> { vao :: G.WebGLVertexArray, buffer :: G.WebGLBuffer }
  -> Effect Unit
startXRSession gl xr uniforms _ vaos leftHand rightHand = do
  session <- XR.requestSession xr "immersive-ar"
  layer <- XR.createXRWebGLLayer session gl
  XR.updateRenderState session layer
  refSpace <- XR.requestReferenceSpace session "local"

  let onFrame :: Number -> XR.XRFrame -> Effect Unit
      onFrame _time frame = do
        sources <- XR.getInputSources session
        handData <- processHandInput frame refSpace sources

        G.bindArrayBuffer gl leftHand.buffer
        G.bufferSubData gl handData.leftVertices

        G.bindArrayBuffer gl rightHand.buffer
        G.bufferSubData gl handData.rightVertices

        -- Check for pinch gestures
        let leftDist = distance3D handData.leftVertices
                         (indexFingerTip * baseNumberOfDimensions)
                         (thumbTip * baseNumberOfDimensions)
        when (leftDist < pinchThreshold) do
          log ("Left pinch detected, distance: " <> show leftDist)

        mPose <- XR.getViewerPose frame refSpace
        case mPose of
          Nothing -> XR.requestAnimationFrame session onFrame
          Just pose -> do
            renderFrame gl uniforms layer vaos pose
            XR.requestAnimationFrame session onFrame

  XR.requestAnimationFrame session onFrame
