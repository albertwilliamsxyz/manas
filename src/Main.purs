module Main where

import Prelude

import Control.Monad.Except (except, runExceptT)
import Data.Array (replicate)
import Data.Either (Either(..), note)
import Data.Foldable (for_)
import Data.Map as Map
import Data.Map (Map, fromFoldable)
import Data.Maybe (fromMaybe)
import Data.Nullable (toMaybe)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Console (log)
import ForeignUtils as ForeignUtils
import Web.DOM.Element as Element
import Web.DOM.NonElementParentNode (getElementById)
import Web.Event.Event (EventType(..))
import Web.Event.EventTarget as EventTarget
import Web.HTML (Navigator, Window, window)
import Web.HTML.HTMLButtonElement as HTMLButtonElement
import Web.HTML.HTMLCanvasElement as HTMLCanvasElement
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window (document, navigator)
import WebGL2 as WebGL2
import WebXR as WebXR


baseNumberOfDimensions :: Int
baseNumberOfDimensions = 3


numberOfJointsPerHand :: Int
numberOfJointsPerHand = 25

numberOfHandJointDimensions :: Int
numberOfHandJointDimensions = numberOfJointsPerHand * baseNumberOfDimensions

handSkeletonByJointIndices :: Array Int
handSkeletonByJointIndices =
  [ 0, 1, 1, 2, 2, 3, 3, 4
  , 0, 5, 5, 6, 6, 7, 7, 8, 8, 9
  , 0, 10, 10, 11, 11, 12, 12, 13, 13, 14
  , 0, 15, 15, 16, 16, 17, 17, 18, 18, 19
  , 0, 20, 20, 21, 21, 22, 22, 23, 23, 24
  ]

handJointIndicesByName :: Map String Int
handJointIndicesByName =
  fromFoldable
    [ Tuple "wrist" 0
    , Tuple "thumb-metacarpal" 1
    , Tuple "thumb-phalanx-proximal" 2
    , Tuple "thumb-phalanx-distal" 3
    , Tuple "thumb-tip" 4
    , Tuple "index-finger-metacarpal" 5
    , Tuple "index-finger-phalanx-proximal" 6
    , Tuple "index-finger-phalanx-intermediate" 7
    , Tuple "index-finger-phalanx-distal" 8
    , Tuple "index-finger-tip" 9
    , Tuple "middle-finger-metacarpal" 10
    , Tuple "middle-finger-phalanx-proximal" 11
    , Tuple "middle-finger-phalanx-intermediate" 12
    , Tuple "middle-finger-phalanx-distal" 13
    , Tuple "middle-finger-tip" 14
    , Tuple "ring-finger-metacarpal" 15
    , Tuple "ring-finger-phalanx-proximal" 16
    , Tuple "ring-finger-phalanx-intermediate" 17
    , Tuple "ring-finger-phalanx-distal" 18
    , Tuple "ring-finger-tip" 19
    , Tuple "pinky-finger-metacarpal" 20
    , Tuple "pinky-finger-phalanx-proximal" 21
    , Tuple "pinky-finger-phalanx-intermediate" 22
    , Tuple "pinky-finger-phalanx-distal" 23
    , Tuple "pinky-finger-tip" 24
    ]

cubeVertices3d :: Array Number
cubeVertices3d =
  [ -0.1, -0.1, 0.1
  ,  0.1, -0.1, 0.1
  ,  0.1,  0.1, 0.1
  , -0.1, -0.1, 0.1
  ,  0.1,  0.1, 0.1
  , -0.1,  0.1, 0.1

  ,  0.1, -0.1, -0.1
  , -0.1, -0.1, -0.1
  , -0.1,  0.1, -0.1
  ,  0.1, -0.1, -0.1
  , -0.1,  0.1, -0.1
  ,  0.1,  0.1, -0.1

  ,  0.1, -0.1, 0.1
  ,  0.1, -0.1, -0.1
  ,  0.1,  0.1, -0.1
  ,  0.1, -0.1, 0.1
  ,  0.1,  0.1, -0.1
  ,  0.1,  0.1, 0.1

  , -0.1, -0.1, -0.1
  , -0.1, -0.1, 0.1
  , -0.1,  0.1, 0.1
  , -0.1, -0.1, -0.1
  , -0.1,  0.1, 0.1
  , -0.1,  0.1, -0.1

  , -0.1,  0.1, 0.1
  ,  0.1,  0.1, 0.1
  ,  0.1,  0.1, -0.1
  , -0.1,  0.1, 0.1
  ,  0.1,  0.1, -0.1
  , -0.1,  0.1, -0.1

  , -0.1, -0.1, -0.1
  ,  0.1, -0.1, -0.1
  ,  0.1, -0.1, 0.1
  , -0.1, -0.1, -0.1
  ,  0.1, -0.1, 0.1
  , -0.1, -0.1, 0.1
  ]


identityMatrix4x4 :: Array Number
identityMatrix4x4 =
  [ 1.0, 0.0, 0.0, 0.0
  , 0.0, 1.0, 0.0, 0.0
  , 0.0, 0.0, 1.0, 0.0
  , 0.0, 0.0, 0.0, 1.0
  ]

identityMatrix4x4Float32 :: ForeignUtils.Float32Array
identityMatrix4x4Float32 = ForeignUtils.float32Array identityMatrix4x4


glslVersionDirective :: String
glslVersionDirective = "#version 300 es"

vertexShaderSourceCode :: String
vertexShaderSourceCode = glslVersionDirective <> """
in vec3 a_position;
uniform mat4 u_projection;
uniform mat4 u_view;
uniform mat4 u_model;
void main() {
  gl_Position = u_projection * u_view * u_model * vec4(a_position, 1.0);
  gl_PointSize = 10.0;
}
"""

fragmentShaderSourceCode :: String
fragmentShaderSourceCode = glslVersionDirective <> """
precision highp float;
out vec4 outColor;
uniform vec4 u_color;
void main() {
  outColor = u_color;
}
"""


main :: Effect Unit
main = launchAff_ do
    result <- runExceptT do
        win <- liftEffect window
        doc <- liftEffect $ document win
        nav <- liftEffect $ navigator win


        maybeApplicationCanvas <- liftEffect $ getElementById "application" (HTMLDocument.toNonElementParentNode doc)
        applicationCanvas <- except $ note "applicationCanvas not found" maybeApplicationCanvas
        applicationCanvasAsElement <- except $ note "applicationCanvas could not be converted to HTMLCanvasElement" (HTMLCanvasElement.fromElement applicationCanvas)


        nullableWebGL2Context <- liftEffect $ WebGL2.createContext applicationCanvasAsElement
        webGL2Context <- except $ note "WebGL2 not supported" (toMaybe nullableWebGL2Context)


        nullableVertexShader <- liftEffect $ WebGL2.createShader webGL2Context WebGL2.vertexShader        
        vertexShader <- except $ note "Vertex shader could not be created" (toMaybe nullableVertexShader)
        liftEffect $ WebGL2.shaderSource webGL2Context vertexShader vertexShaderSourceCode
        liftEffect $ WebGL2.compileShader webGL2Context vertexShader
        vertexShaderCompiledSuccessfully <- liftEffect $ WebGL2.getShaderParameter webGL2Context vertexShader WebGL2.compileStatus
        _ <- if not vertexShaderCompiledSuccessfully
            then do
                nullableErrorMessage <- liftEffect $ WebGL2.getShaderInfoLog webGL2Context vertexShader
                liftEffect $ WebGL2.deleteShader webGL2Context vertexShader
                except $ Left $ fromMaybe "Unknown Error when compiling vertex shader" (toMaybe nullableErrorMessage)
            else do
                except $ Right "Vertex shader compiled successfully"

                
        nullableFragmentShader <- liftEffect $ WebGL2.createShader webGL2Context WebGL2.fragmentShader
        fragmentShader <- except $ note "Fragment shader could not be created" (toMaybe nullableFragmentShader)
        liftEffect $ WebGL2.shaderSource webGL2Context fragmentShader fragmentShaderSourceCode
        liftEffect $ WebGL2.compileShader webGL2Context fragmentShader
        fragmentShaderCompiledSuccessfully <- liftEffect $ WebGL2.getShaderParameter webGL2Context fragmentShader WebGL2.compileStatus
        _ <- if not fragmentShaderCompiledSuccessfully
            then do
                nullableErrorMessage <- liftEffect $ WebGL2.getShaderInfoLog webGL2Context fragmentShader
                liftEffect $ WebGL2.deleteShader webGL2Context fragmentShader
                except $ Left $ fromMaybe "Unknown Error when compiling fragment shader" (toMaybe nullableErrorMessage)
            else do
                except $ Right "Fragment shader compiled successfully"


        nullableProgram <- liftEffect $ WebGL2.createProgram webGL2Context
        program <- except $ note "Program could not be created" (toMaybe nullableProgram)


        liftEffect $ WebGL2.attachShader webGL2Context program vertexShader
        liftEffect $ WebGL2.attachShader webGL2Context program fragmentShader
        liftEffect $ WebGL2.linkProgram webGL2Context program
        programCompiledSuccessfully <- liftEffect $ WebGL2.getProgramParameter webGL2Context program WebGL2.linkStatus
        _ <- if not programCompiledSuccessfully
            then do
                nullableErrorMessage <- liftEffect $ WebGL2.getProgramInfoLog webGL2Context program
                liftEffect $ WebGL2.deleteShader webGL2Context vertexShader
                liftEffect $ WebGL2.deleteShader webGL2Context fragmentShader
                liftEffect $ WebGL2.deleteProgram webGL2Context program
                except $ Left $ fromMaybe "Unknown Error when linking program" (toMaybe nullableErrorMessage)
            else do
                liftEffect $ WebGL2.useProgram webGL2Context program
                except $ Right "Program created successfully"


        positionLocation <- liftEffect $ WebGL2.getAttribLocation webGL2Context program "a_position"
        _ <- if positionLocation == -1
            then except $ Left "Unable to get the location of the position attribute"
            else except $ Right "Position attribute location obtained successfully"

        nullableProjectionLocation <- liftEffect $ WebGL2.getUniformLocation webGL2Context program "u_projection"
        projectionLocation <- except $ note "Unable to get the location of the projection uniform" (toMaybe nullableProjectionLocation)
        liftEffect $ WebGL2.uniformMatrix4fv webGL2Context projectionLocation false identityMatrix4x4Float32

        nullableViewLocation <- liftEffect $ WebGL2.getUniformLocation webGL2Context program "u_view"
        viewLocation <- except $ note "Unable to get the location of the view uniform" (toMaybe nullableViewLocation)
        liftEffect $ WebGL2.uniformMatrix4fv webGL2Context viewLocation false identityMatrix4x4Float32

        nullableModelLocation <- liftEffect $ WebGL2.getUniformLocation webGL2Context program "u_model"
        modelLocation <- except $ note "Unable to get the location of the model uniform" (toMaybe nullableModelLocation)
        liftEffect $ WebGL2.uniformMatrix4fv webGL2Context modelLocation false identityMatrix4x4Float32

        nullableColorLocation <- liftEffect $ WebGL2.getUniformLocation webGL2Context program "u_color"
        colorLocation <- except $ note "Unable to get the location of the color uniform" (toMaybe nullableColorLocation)
        liftEffect $ WebGL2.uniform4fv webGL2Context colorLocation (ForeignUtils.float32Array [0.0, 0.8, 0.0, 1.0])


        -- let cubePosition = WebGL2.float32Array [0.0, 0.0, -0.5]
        -- let cubeRotation = WebGL2.float32Array [0.0, 0.0, 0.0]
        -- let cubeScale = WebGL2.float32Array [1.0, 1.0, 1.0]
        nullableCubeVAO <- liftEffect $ WebGL2.createVertexArray webGL2Context
        cubeVAO <- except $ note "Cube VAO could not be created" (toMaybe nullableCubeVAO)
        nullableCubeBuffer <- liftEffect $ WebGL2.createBuffer webGL2Context
        cubeBuffer <- except $ note "Cube buffer could not be created" (toMaybe nullableCubeBuffer)
        liftEffect $ WebGL2.bindVertexArray webGL2Context cubeVAO
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer cubeBuffer
        liftEffect $ WebGL2.bufferData webGL2Context WebGL2.arrayBuffer (ForeignUtils.float32Array cubeVertices3d) WebGL2.staticDraw
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
        liftEffect $ WebGL2.enable webGL2Context WebGL2.depthTest


        nullableHandSkeletonJointIndicesBuffer <- liftEffect $ WebGL2.createBuffer webGL2Context
        handSkeletonJointIndicesBuffer <- except $ note "Hand skeleton joint indices buffer could not be created" (toMaybe nullableHandSkeletonJointIndicesBuffer)
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer handSkeletonJointIndicesBuffer
        liftEffect $ WebGL2.bufferData webGL2Context WebGL2.elementArrayBuffer (ForeignUtils.uint16Array handSkeletonByJointIndices) WebGL2.staticDraw


        nullableLeftHandVAO <- liftEffect $ WebGL2.createVertexArray webGL2Context
        leftHandVAO <- except $ note "Left hand VAO could not be created" (toMaybe nullableLeftHandVAO)
        nullableLeftHandBuffer <- liftEffect $ WebGL2.createBuffer webGL2Context
        leftHandBuffer <- except $ note "Left hand buffer could not be created" (toMaybe nullableLeftHandBuffer)
        liftEffect $ WebGL2.bindVertexArray webGL2Context leftHandVAO
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer leftHandBuffer
        liftEffect $ WebGL2.bufferData webGL2Context WebGL2.arrayBuffer (
            ForeignUtils.float32Array (replicate (numberOfJointsPerHand * baseNumberOfDimensions) 0.0)
        ) WebGL2.dynamicDraw
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation

        nullableLeftHandSkeletonVAO <- liftEffect $ WebGL2.createVertexArray webGL2Context
        leftHandSkeletonVAO <- except $ note "Left hand skeleton VAO could not be created" (toMaybe nullableLeftHandSkeletonVAO)
        liftEffect $ WebGL2.bindVertexArray webGL2Context leftHandSkeletonVAO
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer leftHandBuffer
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer handSkeletonJointIndicesBuffer


        nullableRightHandVAO <- liftEffect $ WebGL2.createVertexArray webGL2Context
        rightHandVAO <- except $ note "Right hand VAO could not be created" (toMaybe nullableRightHandVAO)
        nullableRightHandBuffer <- liftEffect $ WebGL2.createBuffer webGL2Context
        rightHandBuffer <- except $ note "Right hand buffer could not be created" (toMaybe nullableRightHandBuffer)
        liftEffect $ WebGL2.bindVertexArray webGL2Context rightHandVAO
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer rightHandBuffer
        liftEffect $ WebGL2.bufferData webGL2Context WebGL2.arrayBuffer (
            ForeignUtils.float32Array (replicate (numberOfJointsPerHand * baseNumberOfDimensions) 0.0)
        ) WebGL2.dynamicDraw
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation

        nullableRightHandSkeletonVAO <- liftEffect $ WebGL2.createVertexArray webGL2Context
        rightHandSkeletonVAO <- except $ note "Right hand skeleton VAO could not be created" (toMaybe nullableRightHandSkeletonVAO)
        liftEffect $ WebGL2.bindVertexArray webGL2Context rightHandSkeletonVAO
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer rightHandBuffer
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer handSkeletonJointIndicesBuffer

        maybeStartButton <- liftEffect $ getElementById "start-experience" (HTMLDocument.toNonElementParentNode doc)
        startButtonElement <- except $ note "Start experience button not found" maybeStartButton
        maybeStartButtonAsHtmlButtonElement <- pure $ HTMLButtonElement.fromElement startButtonElement
        startButtonAsHtmlButtonElement <- except $ note "Start experience button could not be converted to HTMLButtonElement" maybeStartButtonAsHtmlButtonElement
        let eventTarget = Element.toEventTarget (HTMLElement.toElement (HTMLButtonElement.toHTMLElement startButtonAsHtmlButtonElement))
        listener <- liftEffect $ EventTarget.eventListener \_ -> launchAff_ $ do
            result' <- runExperience win nav webGL2Context
            case result' of
                Left err -> liftEffect $ log $ "VR Experience error: " <> err
                Right _ -> pure unit
        _ <- liftEffect $ EventTarget.addEventListener (EventType "click") listener false eventTarget
        except $ Right "Start experience button event listener added successfully"
    liftEffect $ case result of
        Left errorMessage -> log errorMessage
        Right message -> log message


runExperience :: Window -> Navigator -> WebGL2.RenderingContext -> Aff (Either String Unit)
runExperience win nav webGL2Context = runExceptT do
    nullableXRSystem <- liftEffect $ WebXR.getXRSystem nav
    xrSystem <- except $ note "WebXR not supported" (toMaybe nullableXRSystem)


    isWebXRSessionModeSupported <- liftAff $ WebXR.isWebXRSessionModeSupported xrSystem "immersive-ar"
    _ <- if not isWebXRSessionModeSupported
        then except $ Left "WebXR session mode not supported"
        else except $ Right "WebXR session mode supported"
    liftAff $ WebXR.makeXRWebGL2Compatible webGL2Context


    xrSession <- liftAff $ WebXR.requestSession xrSystem "immersive-ar" { optionalFeatures: ["hit-test", "hand-tracking"] }
    xrGLLayer <- liftEffect $ WebXR.createXRWebGLLayer win xrSession webGL2Context
    liftEffect $ WebXR.updateRenderState xrSession { baseLayer: xrGLLayer }

    referenceSpace <- liftAff $ WebXR.requestReferenceSpace xrSession "local"

    -- let drawingVertices = ForeignUtils.float32Array (replicate (numberOfHandJointDimensions) 0.0)

    let tick :: WebXR.XRFrameRequestCallback
        tick _ frame = do
            let leftHandVertices = ForeignUtils.float32Array (replicate (numberOfHandJointDimensions) 0.0)
            let rightHandVertices = ForeignUtils.float32Array (replicate (numberOfHandJointDimensions) 0.0)

            inputSources <- WebXR.getInputSources xrSession
            for_ inputSources \inputSource -> void $ runExceptT do
              nullableHand <- liftEffect $ WebXR.getHand inputSource
              hand <- except $ note "Input source has no hand data" (toMaybe nullableHand)

              nullableHandedness <- liftEffect $ WebXR.getHandedness inputSource
              handedness <- except $ note "Handedness unknown" (toMaybe nullableHandedness)

              verticesReference <- case handedness of
                "left" -> pure leftHandVertices
                "right" -> pure rightHandVertices
                _ -> except $ Left ("Handedness unknown: " <> handedness)

              joints <- liftEffect $ WebXR.getHandJoints hand
              for_ joints \(Tuple jointName jointSpace) -> void $ runExceptT do
                nullableJointPose <- liftEffect $ WebXR.getJointPose frame jointSpace referenceSpace
                jointPose <- except $ note "No joint pose" (toMaybe nullableJointPose)

                index <- except $ note ("Unknown joint name: " <> jointName) (Map.lookup jointName handJointIndicesByName)

                positionArray <- liftEffect $ WebXR.getJointPosition jointPose
                let offset = index * 3
                liftEffect $ ForeignUtils.copyInto verticesReference positionArray offset
              pure unit

            --       gl.bindBuffer(gl.ARRAY_BUFFER, leftHandBuffer)
            --       gl.bufferSubData(gl.ARRAY_BUFFER, 0, new Float32Array(leftHandVertices), 0, leftHandVertices.length)
            --
            --       gl.bindBuffer(gl.ARRAY_BUFFER, rightHandBuffer)
            --       gl.bufferSubData(gl.ARRAY_BUFFER, 0, new Float32Array(rightHandVertices), 0, rightHandVertices.length)
            --
            --       if (leftHandVertices.length) {
            --         const leftHandIndexFingerTipIndex: Float32Array = leftHandVertices.subarray(
            --           HAND_JOINT_INDICES_BY_NAME['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS,
            --           HAND_JOINT_INDICES_BY_NAME['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
            --         )
            --         const leftHandThumbTipIndex: Float32Array = leftHandVertices.subarray(
            --           HAND_JOINT_INDICES_BY_NAME['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS,
            --           HAND_JOINT_INDICES_BY_NAME['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
            --         )
            --         const distanceBetweenLeftHandIndexFingerTipAndThumbTip: number = Math.sqrt(
            --           (leftHandIndexFingerTipIndex[0] - leftHandThumbTipIndex[0]) ** 2 +
            --           (leftHandIndexFingerTipIndex[1] - leftHandThumbTipIndex[1]) ** 2 +
            --           (leftHandIndexFingerTipIndex[2] - leftHandThumbTipIndex[2]) ** 2
            --         )
            --         console.log('Distance between left hand index finger tip and thumb tip:', distanceBetweenLeftHandIndexFingerTipAndThumbTip)
            --         if (distanceBetweenLeftHandIndexFingerTipAndThumbTip < 0.02) {
            --           // CODE Interactions
            --           // Take the cube position and update it based on the difference between the start of the event and the end
            --         }
            --       }
            --
            --       if (rightHandVertices.length) {
            --         const rightHandIndexFingerTipIndex: Float32Array = rightHandVertices.subarray(
            --           HAND_JOINT_INDICES_BY_NAME['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS,
            --           HAND_JOINT_INDICES_BY_NAME['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
            --         )
            --         const rightHandThumbTipIndex: Float32Array = rightHandVertices.subarray(
            --           HAND_JOINT_INDICES_BY_NAME['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS,
            --           HAND_JOINT_INDICES_BY_NAME['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
            --         )
            --         const distanceBetweenrightHandIndexFingerTipAndThumbTip: number = Math.sqrt(
            --           (rightHandIndexFingerTipIndex[0] - rightHandThumbTipIndex[0]) ** 2 +
            --           (rightHandIndexFingerTipIndex[1] - rightHandThumbTipIndex[1]) ** 2 +
            --           (rightHandIndexFingerTipIndex[2] - rightHandThumbTipIndex[2]) ** 2
            --         )
            --         if (distanceBetweenrightHandIndexFingerTipAndThumbTip < 0.02) {
            --         }
            --       }
            --
            --       const pose: XRViewerPose | undefined = frame.getViewerPose(referenceSpace)
            --       if (!pose) {
            --         xrSession.requestAnimationFrame(onXRFrame)
            --         return
            --       }
            --
            --       gl.bindFramebuffer(gl.FRAMEBUFFER, xrGLLayer.framebuffer)
            --
            --       gl.clearColor(0.0, 0.0, 0.0, 0.3)
            --       gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
            --
            --       for (const view of pose.views) {
            --         const viewport: XRViewport | undefined = xrGLLayer.getViewport(view)
            --         if (!viewport) continue
            --
            --         gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height)
            --
            --         gl.uniformMatrix4fv(projectionLocation, false, view.projectionMatrix)
            --         gl.uniformMatrix4fv(viewLocation, false, view.transform.inverse.matrix)
            --         gl.uniformMatrix4fv(modelLocation, false, new Float32Array(IDENTITY_MATRIX))
            --
            --         gl.bindVertexArray(leftHandVAO)
            --         gl.drawArrays(gl.POINTS, 0, NUMBER_OF_JOINTS_PER_HAND)
            --
            --         gl.bindVertexArray(leftHandSkeletonVAO)
            --         gl.drawElements(gl.LINES, HAND_SKELETON_BY_JOINT_INDICES.length, gl.UNSIGNED_SHORT, 0)
            --
            --         gl.bindVertexArray(rightHandVAO)
            --         gl.drawArrays(gl.POINTS, 0, NUMBER_OF_JOINTS_PER_HAND)
            --
            --         gl.bindVertexArray(rightHandSkeletonVAO)
            --         gl.drawElements(gl.LINES, HAND_SKELETON_BY_JOINT_INDICES.length, gl.UNSIGNED_SHORT, 0)
            --
            --         // render the scene graphic data
            --         // For each model take the corresponding matrices and multiply them here, then pass the resulting matrix to the shader and render the model
            --         // CODE
            --         gl.bindVertexArray(cubeVAO)
            --         gl.drawArrays(gl.POINTS, 0, CUBE_VERTICES.length / BASE_NUMBER_OF_DIMENSIONS)
            --       }
            --
            --       xrSession.requestAnimationFrame(onXRFrame)
            _ <- liftEffect $ WebXR.requestAnimationFrame xrSession tick
            pure unit
    _ <- liftEffect $ WebXR.requestAnimationFrame xrSession tick
    pure unit
