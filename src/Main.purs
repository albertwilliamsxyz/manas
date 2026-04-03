module Main where

import Prelude

import Control.Monad.Except (ExceptT, except, runExceptT)
import Data.Array (length, replicate, uncons, (!!))
import Data.Either (Either(..), note)
import Data.Foldable (for_)
import Data.Int.Bits ((.|.))
import Data.Map (Map, fromFoldable)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (toMaybe)
import Data.Tuple (Tuple(..), fst)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Effect.Random (random)
import Effect.Ref as Ref
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


-- [Constants]

-- [Essentials]

baseNumberOfDimensions :: Int
baseNumberOfDimensions = 3

-- [WebXR / Hand Tracking]

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

pinchThreshold :: Number
pinchThreshold = 0.02

-- [Geometry]

cubeVertices :: Array Number
cubeVertices =
    [ -0.1, -0.1,  0.1   -- 0: front bottom left
    ,  0.1, -0.1,  0.1   -- 1: front bottom right
    ,  0.1,  0.1,  0.1   -- 2: front top right
    , -0.1,  0.1,  0.1   -- 3: front top left
    , -0.1, -0.1, -0.1   -- 4: back bottom left
    ,  0.1, -0.1, -0.1   -- 5: back bottom right
    ,  0.1,  0.1, -0.1   -- 6: back top right
    , -0.1,  0.1, -0.1   -- 7: back top left
    ]

cubeEdgeIndices :: Array Int
cubeEdgeIndices =
    [ 0, 1, 1, 2, 2, 3, 3, 0   -- front face edges
    , 4, 5, 5, 6, 6, 7, 7, 4   -- back face edges
    , 0, 4, 1, 5, 2, 6, 3, 7   -- connecting edges
    ]

cubeTriangleIndices :: Array Int
cubeTriangleIndices =
    [ 0, 1, 2, 0, 2, 3   -- front
    , 5, 4, 7, 5, 7, 6   -- back
    , 1, 5, 6, 1, 6, 2   -- right
    , 4, 0, 3, 4, 3, 7   -- left
    , 3, 2, 6, 3, 6, 7   -- top
    , 4, 5, 1, 4, 1, 0   -- bottom
    ]

-- [Mathematics]

identityMatrix4x4 :: Array Number
identityMatrix4x4 =
  [ 1.0, 0.0, 0.0, 0.0
  , 0.0, 1.0, 0.0, 0.0
  , 0.0, 0.0, 1.0, 0.0
  , 0.0, 0.0, 0.0, 1.0
  ]

identityMatrix4x4Float32 :: ForeignUtils.Float32Array
identityMatrix4x4Float32 = ForeignUtils.float32Array identityMatrix4x4

-- [WebGL Shaders]

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


-- [Types]

-- [Geometry types]

data Topology = Points | Lines | Triangles

newtype GeometryId = GeometryId String

derive instance eqGeometryId :: Eq GeometryId
derive instance ordGeometryId :: Ord GeometryId

type Geometry =
    { vertices :: Array Number
    , edgeIndices :: Array Int
    , triangleIndices :: Array Int
    , topology :: Topology
    }

type Transform = 
    { translation :: ForeignUtils.Float32Array
    , rotation :: ForeignUtils.Float32Array
    , scale :: ForeignUtils.Float32Array
    }

type Ray = 
    { origin :: ForeignUtils.Float32Array
    , direction :: ForeignUtils.Float32Array
    }

-- [WebGL resource types]

type GPUHandle =
    { vao :: WebGL2.VertexArrayObject
    , vertexBuffer :: WebGL2.Buffer
    , indexBuffer :: WebGL2.Buffer
    , drawMode :: Int
    , vertexCount :: Int
    }

-- [Input types]

data Handedness = LeftHand | RightHand

type HandInput = { jointPositions :: ForeignUtils.Float32Array }

type Hands =
    { left :: Maybe HandInput
    , right :: Maybe HandInput
    }

type ControllerInput = 
    { position :: ForeignUtils.Float32Array,
    orientation :: ForeignUtils.Float32Array 
    }

type Controllers =
    { left :: Maybe ControllerInput
    , right :: Maybe ControllerInput
    }

type InputState =
    { hands :: Hands
    , controllers :: Controllers
    }

-- [Interaction types]

type GrabState =
    { heldObject :: Maybe SceneObjectId
    , grabOffset :: Maybe ForeignUtils.Float32Array
    , wasPinching :: Boolean
    }

-- [Scene types]

newtype SceneObjectId = SceneObjectId String

derive instance eqSceneObjectId :: Eq SceneObjectId
derive instance ordSceneObjectId :: Ord SceneObjectId

type SceneObject = 
    { geometryId :: GeometryId
    , transform :: Transform
    }

-- [World State type]

type WorldState =
    { geometries :: Map GeometryId Geometry
    , gpuHandles :: Map GeometryId GPUHandle
    , sceneObjects :: Map SceneObjectId SceneObject
    , nextObjectId :: Int
    , inputs :: InputState
    , interaction :: { left :: GrabState, right :: GrabState }
    }


-- [Functions]

-- [Mathematics]

generateRandomTranslationMatrix4x4Float32 :: Effect (ForeignUtils.Float32Array)
generateRandomTranslationMatrix4x4Float32 = do
    tx <- random
    ty <- random
    tz <- random
    pure $ ForeignUtils.float32Array
        [ 1.0, 0.0, 0.0, 0.0
        , 0.0, 1.0, 0.0, 0.0
        , 0.0, 0.0, 1.0, 0.0
        , tx, ty, tz, 1.0
        ]

getVertex :: Array Number -> Int -> ForeignUtils.Float32Array
getVertex vertices i = 
    let offset = i * 3
        x = fromMaybe 0.0 (vertices !! offset)
        y = fromMaybe 0.0 (vertices !! (offset + 1))
        z = fromMaybe 0.0 (vertices !! (offset + 2))
    in ForeignUtils.float32Array [x, y, z]

rayMeshIntersect 
    :: { origin :: ForeignUtils.Float32Array, direction :: ForeignUtils.Float32Array } 
    -> ForeignUtils.Float32Array 
    -> Geometry 
    -> Maybe Number
rayMeshIntersect ray modelMatrix geometry = 
    go 0 Nothing
    where
    verts = geometry.vertices
    indices = geometry.triangleIndices
    numTriangles = length indices / 3
    
    go :: Int -> Maybe Number -> Maybe Number
    go i closest
        | i >= numTriangles = closest
        | otherwise = 
            let idx = i * 3
                i0 = fromMaybe 0 (indices !! idx)
                i1 = fromMaybe 0 (indices !! (idx + 1))
                i2 = fromMaybe 0 (indices !! (idx + 2))
                v0 = ForeignUtils.transformPoint3 modelMatrix (getVertex verts i0)
                v1 = ForeignUtils.transformPoint3 modelMatrix (getVertex verts i1)
                v2 = ForeignUtils.transformPoint3 modelMatrix (getVertex verts i2)
                hit = toMaybe (ForeignUtils.rayTriangleIntersect ray v0 v1 v2)
            in case hit, closest of
                Just t, Nothing -> go (i + 1) (Just t)
                Just t, Just prev -> go (i + 1) (Just (min t prev))
                Nothing, _ -> go (i + 1) closest


-- [Utilities]

topologyToDrawMode :: Topology -> Int
topologyToDrawMode Points = WebGL2.points
topologyToDrawMode Lines = WebGL2.lines
topologyToDrawMode Triangles = WebGL2.triangles

addCubeToScene :: ForeignUtils.Float32Array -> WorldState -> WorldState
addCubeToScene position worldState = worldState
    { sceneObjects = Map.insert newId newObject worldState.sceneObjects
    , nextObjectId = worldState.nextObjectId + 1
    }
    where
        newId = SceneObjectId (show worldState.nextObjectId)
        newObject =
            { geometryId: GeometryId "cube"
            , transform:
                { translation: position
                , rotation: identityMatrix4x4Float32
                , scale: identityMatrix4x4Float32
                }
            }

uploadGeometry :: WebGL2.RenderingContext -> Int -> Geometry -> ExceptT String Effect GPUHandle
uploadGeometry webGL2Context positionLocation geometry = do
    nullableVAO <- liftEffect $ WebGL2.createVertexArray webGL2Context
    vao <- except $ note "VAO could not be created" (toMaybe nullableVAO)
    nullableVertexBuffer <- liftEffect $ WebGL2.createBuffer webGL2Context
    vertexBuffer <- except $ note "Vertex buffer could not be created" (toMaybe nullableVertexBuffer)
    nullableIndexBuffer <- liftEffect $ WebGL2.createBuffer webGL2Context
    indexBuffer <- except $ note "Index buffer could not be created" (toMaybe nullableIndexBuffer)
    liftEffect $ WebGL2.bindVertexArray webGL2Context vao
    liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer vertexBuffer
    liftEffect $ WebGL2.bufferData webGL2Context WebGL2.arrayBuffer (ForeignUtils.float32Array geometry.vertices) WebGL2.staticDraw
    liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer indexBuffer
    liftEffect $ WebGL2.bufferData webGL2Context WebGL2.elementArrayBuffer (ForeignUtils.uint16Array geometry.edgeIndices) WebGL2.staticDraw
    liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
    liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
    liftEffect $ WebGL2.unbindVertexArray webGL2Context
    pure { vao
         , vertexBuffer
         , indexBuffer
         , drawMode: topologyToDrawMode geometry.topology
         , vertexCount: length geometry.edgeIndices
         }

makeTranslationMatrix :: ForeignUtils.Float32Array -> Effect ForeignUtils.Float32Array
makeTranslationMatrix position = do
    x <- ForeignUtils.getAt position 0
    y <- ForeignUtils.getAt position 1
    z <- ForeignUtils.getAt position 2
    pure $ ForeignUtils.float32Array
        [ 1.0, 0.0, 0.0, 0.0
        , 0.0, 1.0, 0.0, 0.0
        , 0.0, 0.0, 1.0, 0.0
        , x, y, z, 1.0
        ]

composeModelMatrix :: Transform -> ForeignUtils.Float32Array
composeModelMatrix transform = 
    ForeignUtils.multiplyMatrix4x4 transform.translation 
        (ForeignUtils.multiplyMatrix4x4 transform.rotation transform.scale)

findHitObject 
    :: { origin :: ForeignUtils.Float32Array, direction :: ForeignUtils.Float32Array }
    -> WorldState 
    -> Maybe SceneObjectId
findHitObject ray worldState = 
    go (Map.toUnfoldable worldState.sceneObjects :: Array (Tuple SceneObjectId SceneObject)) Nothing
    where
    go entries acc = case uncons entries of
        Nothing -> fst <$> acc
        Just { head: Tuple objId obj, tail: rest } ->
            case Map.lookup obj.geometryId worldState.geometries of
                Nothing -> go rest acc
                Just geom -> 
                    let modelMatrix = composeModelMatrix obj.transform
                        hit = rayMeshIntersect ray modelMatrix geom
                    in case hit, acc of
                        Just t, Nothing -> go rest (Just (Tuple objId t))
                        Just t, Just (Tuple _ prevT) 
                            | t < prevT -> go rest (Just (Tuple objId t))
                        _, _ -> go rest acc

findNearestObject 
    :: ForeignUtils.Float32Array
    -> Map SceneObjectId SceneObject
    -> Maybe SceneObjectId
findNearestObject pinchPoint sceneObjects = 
    go (Map.toUnfoldable sceneObjects :: Array (Tuple SceneObjectId SceneObject)) Nothing
    where
    grabRadius = 0.15

    go entries acc = case uncons entries of
        Nothing -> fst <$> acc
        Just { head: Tuple objId obj, tail: rest } ->
            let modelMatrix = composeModelMatrix obj.transform
                dist = ForeignUtils.get3DDistanceFromMatrix pinchPoint modelMatrix
            in if dist < grabRadius
                then case acc of
                    Nothing -> go rest (Just (Tuple objId dist))
                    Just (Tuple _ prevDist) 
                        | dist < prevDist -> go rest (Just (Tuple objId dist))
                        | otherwise -> go rest acc
                else go rest acc

updateGrab 
    :: Boolean
    -> ForeignUtils.Float32Array
    -> Maybe { id :: SceneObjectId, position :: ForeignUtils.Float32Array }
    -> GrabState
    -> GrabState
updateGrab isPinching pinchPosition hitResult grabState = 
    let result = case isPinching, grabState.heldObject of
            false, Nothing -> grabState
            false, Just _  -> grabState { heldObject = Nothing, grabOffset = Nothing }
            true, Just _   -> grabState
            true, Nothing  -> case hitResult of
                Nothing -> grabState
                Just hit -> grabState 
                    { heldObject = Just hit.id
                    , grabOffset = Just (ForeignUtils.sub3 pinchPosition hit.position)
                    }
    in result { wasPinching = isPinching }

applyGrab 
    :: ForeignUtils.Float32Array
    -> GrabState
    -> Map SceneObjectId SceneObject
    -> Map SceneObjectId SceneObject
applyGrab pinchPosition grabState sceneObjects = 
    case grabState.heldObject, grabState.grabOffset of
        Just objId, Just offset ->
            let newPosition = ForeignUtils.sub3 pinchPosition offset
            in Map.update (\obj -> Just obj { transform = obj.transform { translation = ForeignUtils.translationMatrix4x4 newPosition } }) objId sceneObjects
        _, _ -> sceneObjects


-- [Main]
main :: Effect Unit
main = launchAff_ do
    result <- runExceptT do
        -- [Getting HTML resources]
        win <- liftEffect window
        doc <- liftEffect $ document win
        nav <- liftEffect $ navigator win

        maybeApplicationCanvas <- liftEffect $ getElementById "application" (HTMLDocument.toNonElementParentNode doc)
        applicationCanvas <- except $ note "applicationCanvas not found" maybeApplicationCanvas
        applicationCanvasAsElement <- except $ note "applicationCanvas could not be converted to HTMLCanvasElement" (HTMLCanvasElement.fromElement applicationCanvas)

        -- [Setting up WebGL2 context and resources]
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

        liftEffect $ WebGL2.enable webGL2Context WebGL2.depthTest

        -- [Getting the WebGL location of shader attributes and uniforms, and setting up initial values]
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

        -- [WIP: Abstracting new structure]

        let cubeGeometryId = GeometryId "cube"
            cubeGeometry =
                { vertices: cubeVertices
                , edgeIndices: cubeEdgeIndices
                ,triangleIndices: cubeTriangleIndices
                , topology: Lines
                }

        cubeGPUHandleResult <- liftEffect $ runExceptT $ uploadGeometry webGL2Context positionLocation cubeGeometry
        cubeGPUHandle <- except cubeGPUHandleResult

        cubePosition <- liftEffect $ generateRandomTranslationMatrix4x4Float32
        let cubeSceneObjectId = SceneObjectId "cube-instance-1"
            cubeSceneObject =
                { geometryId: cubeGeometryId
                , transform:
                    { translation: cubePosition
                    , rotation: identityMatrix4x4Float32
                    , scale: identityMatrix4x4Float32
                    }
                }

        let sceneObjects = Map.singleton cubeSceneObjectId cubeSceneObject
            geometries = Map.singleton cubeGeometryId cubeGeometry
            gpuHandles = Map.singleton cubeGeometryId cubeGPUHandle

        let initialWorldState =
                { geometries
                , gpuHandles
                , sceneObjects
                , nextObjectId: 1
                , inputs:
                    { hands:
                        { left: Nothing
                        , right: Nothing
                        }
                    , controllers:
                        { left: Nothing
                        , right: Nothing
                        }
                    }
                , interaction:
                    { left: { heldObject: Nothing, grabOffset: Nothing, wasPinching: false }
                    , right: { heldObject: Nothing, grabOffset: Nothing, wasPinching: false }
                    }
                }

        worldStateRef <- liftEffect $ Ref.new initialWorldState

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
        liftEffect $ WebGL2.unbindVertexArray webGL2Context

        nullableLeftHandSkeletonVAO <- liftEffect $ WebGL2.createVertexArray webGL2Context
        leftHandSkeletonVAO <- except $ note "Left hand skeleton VAO could not be created" (toMaybe nullableLeftHandSkeletonVAO)
        liftEffect $ WebGL2.bindVertexArray webGL2Context leftHandSkeletonVAO
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer leftHandBuffer
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer handSkeletonJointIndicesBuffer
        liftEffect $ WebGL2.unbindVertexArray webGL2Context

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
        liftEffect $ WebGL2.unbindVertexArray webGL2Context

        nullableRightHandSkeletonVAO <- liftEffect $ WebGL2.createVertexArray webGL2Context
        rightHandSkeletonVAO <- except $ note "Right hand skeleton VAO could not be created" (toMaybe nullableRightHandSkeletonVAO)
        liftEffect $ WebGL2.bindVertexArray webGL2Context rightHandSkeletonVAO
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer rightHandBuffer
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer handSkeletonJointIndicesBuffer
        liftEffect $ WebGL2.unbindVertexArray webGL2Context

        -- [Starting the experience on button click and running the main loop]
        let runExperience :: Window -> Navigator -> WebGL2.RenderingContext -> Aff (Either String Unit)
            runExperience xrWin xrNav xrWebGL2Context = runExceptT do
                -- [Getting the XR-related resources]
                nullableXRSystem <- liftEffect $ WebXR.getXRSystem xrNav
                xrSystem <- except $ note "WebXR not supported" (toMaybe nullableXRSystem)

                isWebXRSessionModeSupported <- liftAff $ WebXR.isWebXRSessionModeSupported xrSystem "immersive-ar"
                _ <- if not isWebXRSessionModeSupported
                    then except $ Left "WebXR session mode not supported"
                    else except $ Right "WebXR session mode supported"
                liftAff $ WebXR.makeXRWebGL2Compatible xrWebGL2Context

                xrSession <- liftAff $ WebXR.requestSession xrSystem "immersive-ar" { requiredFeatures: ["hand-tracking"] }
                xrGLLayer <- liftEffect $ WebXR.createXRWebGLLayer xrWin xrSession xrWebGL2Context
                liftEffect $ WebXR.updateRenderState xrSession { baseLayer: xrGLLayer }

                referenceSpace <- liftAff $ WebXR.requestReferenceSpace xrSession "local"

                let leftHandVertices = ForeignUtils.float32Array (replicate (numberOfHandJointDimensions) 0.0)
                    rightHandVertices = ForeignUtils.float32Array (replicate (numberOfHandJointDimensions) 0.0)

                -- [Callback for tick updates from the XR session]
                let tick :: WebXR.XRFrameRequestCallback
                    tick _ frame = do
                        result <- runExceptT do
                            -- [Managing hand tracking data]
                            inputSources <- liftEffect $ WebXR.getInputSources xrSession
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
                                for_ joints \joint -> do
                                    jointResult <- runExceptT do
                                        nullableJointPose <- liftEffect $ WebXR.getJointPose frame joint.space referenceSpace
                                        jointPose <- except $ note "No joint pose" (toMaybe nullableJointPose)
                                        index <- except $ note ("Unknown joint name: " <> joint.name) (Map.lookup joint.name handJointIndicesByName)
                                        positionArray <- liftEffect $ WebXR.getJointPosition jointPose
                                        let offset = index * 3
                                        liftEffect $ ForeignUtils.copyInto verticesReference positionArray offset
                                    case jointResult of
                                        Left err -> liftEffect $ log $ "Joint Loop Error (" <> joint.name <> "): " <> err
                                        Right _ -> pure unit

                            liftEffect $ WebGL2.bindBuffer xrWebGL2Context WebGL2.arrayBuffer leftHandBuffer
                            liftEffect $ WebGL2.bufferSubData xrWebGL2Context WebGL2.arrayBuffer 0 leftHandVertices
                            liftEffect $ WebGL2.bindBuffer xrWebGL2Context WebGL2.arrayBuffer rightHandBuffer
                            liftEffect $ WebGL2.bufferSubData xrWebGL2Context WebGL2.arrayBuffer 0 rightHandVertices

                            -- [Managing gestures]

                            worldState <- liftEffect $ Ref.read worldStateRef

                            let maybeIndexFingerTipIndex = Map.lookup "index-finger-tip" handJointIndicesByName
                            let maybeThumbTipIndex = Map.lookup "thumb-tip" handJointIndicesByName
                            indexFingerTipIndex <- except $ note "No index-finger-tip index" maybeIndexFingerTipIndex
                            thumbTipIndex <- except $ note "No thumb-tip index" maybeThumbTipIndex
                            let indexFingerTipStart = indexFingerTipIndex * baseNumberOfDimensions
                            let thumbTipStart = thumbTipIndex * baseNumberOfDimensions

                            rightIndexFingerTipPosition <- liftEffect $ ForeignUtils.subarray rightHandVertices indexFingerTipStart (indexFingerTipStart + baseNumberOfDimensions)
                            rightThumbTipPosition <- liftEffect $ ForeignUtils.subarray rightHandVertices thumbTipStart (thumbTipStart + baseNumberOfDimensions)
                            rightThumbIndexDistance <- liftEffect $ ForeignUtils.get3DDistance rightIndexFingerTipPosition rightThumbTipPosition
                            let rightIsPinching = rightThumbIndexDistance < pinchThreshold
                            let rightHit = case rightIsPinching, worldState.interaction.right.heldObject of
                                    true, Nothing ->
                                        case findNearestObject rightIndexFingerTipPosition worldState.sceneObjects of
                                            Just objId -> case Map.lookup objId worldState.sceneObjects of
                                                Just obj -> Just { id: objId, position: ForeignUtils.getTranslationFromMatrix (composeModelMatrix obj.transform) }
                                                Nothing -> Nothing
                                            Nothing -> Nothing
                                    _, _ -> Nothing
                            let rightHandUpdate = updateGrab rightIsPinching rightIndexFingerTipPosition rightHit worldState.interaction.right
                            let rightSceneObjects = applyGrab rightIndexFingerTipPosition rightHandUpdate worldState.sceneObjects

                            leftIndexFingerTipPosition <- liftEffect $ ForeignUtils.subarray leftHandVertices indexFingerTipStart (indexFingerTipStart + baseNumberOfDimensions)
                            leftThumbTipPosition <- liftEffect $ ForeignUtils.subarray leftHandVertices thumbTipStart (thumbTipStart + baseNumberOfDimensions)
                            leftThumbIndexDistance <- liftEffect $ ForeignUtils.get3DDistance leftIndexFingerTipPosition leftThumbTipPosition
                            let leftIsPinching = leftThumbIndexDistance < pinchThreshold
                            let leftHit = case leftIsPinching, worldState.interaction.left.heldObject of
                                    true, Nothing ->
                                        case findNearestObject leftIndexFingerTipPosition rightSceneObjects of
                                            Just objId -> case Map.lookup objId rightSceneObjects of
                                                Just obj -> Just { id: objId, position: ForeignUtils.getTranslationFromMatrix (composeModelMatrix obj.transform) }
                                                Nothing -> Nothing
                                            Nothing -> Nothing
                                    _, _ -> Nothing
                            let leftHandUpdate = updateGrab leftIsPinching leftIndexFingerTipPosition leftHit worldState.interaction.left
                            let finalSceneObjects = applyGrab leftIndexFingerTipPosition leftHandUpdate rightSceneObjects

                            liftEffect $ Ref.modify_ (\ws -> ws 
                                { sceneObjects = finalSceneObjects
                                , interaction = { right: rightHandUpdate, left: leftHandUpdate }
                                }) worldStateRef

                            let leftJustStartedPinching = leftIsPinching && not worldState.interaction.left.wasPinching
                            case leftHit of
                                Nothing -> when leftJustStartedPinching do
                                    translationMatrix <- liftEffect $ makeTranslationMatrix leftIndexFingerTipPosition
                                    liftEffect $ Ref.modify_ (addCubeToScene translationMatrix) worldStateRef
                                _ -> pure unit

                            -- [Managing rendering]
                            framebuffer <- liftEffect $ WebXR.getFramebuffer xrGLLayer
                            liftEffect $ WebGL2.bindFramebuffer xrWebGL2Context WebGL2.framebuffer framebuffer
                            liftEffect $ WebGL2.clearColor xrWebGL2Context 0.0 0.0 0.0 1.0
                            liftEffect $ WebGL2.clear xrWebGL2Context (WebGL2.colorBufferBit .|. WebGL2.depthBufferBit)

                            nullableViewerPose <- liftEffect $ WebXR.getViewerPose frame referenceSpace
                            case toMaybe nullableViewerPose of
                              Nothing -> pure unit
                              Just viewerPose -> do
                                views <- liftEffect $ WebXR.getViews viewerPose
                                for_ views \view -> do
                                  -- [Managing rendering for each view (eye)]
                                  nullableViewport <- liftEffect $ WebXR.getViewport xrGLLayer view
                                  viewport <- except $ note "no viewport" (toMaybe nullableViewport)
                                  liftEffect $ WebGL2.viewport xrWebGL2Context viewport.x viewport.y viewport.width viewport.height

                                  -- [Sending data to WebGL2 to have the context render the scene from the perspective of the current view]
                                  projectionMatrix <- liftEffect $ WebXR.getProjectionMatrix view
                                  viewMatrix <- liftEffect $ WebXR.getViewMatrix view
                                  liftEffect $ WebGL2.uniformMatrix4fv xrWebGL2Context projectionLocation false projectionMatrix
                                  liftEffect $ WebGL2.uniformMatrix4fv xrWebGL2Context viewLocation false viewMatrix
                                  liftEffect $ WebGL2.uniformMatrix4fv xrWebGL2Context modelLocation false identityMatrix4x4Float32

                                  -- [Rendering]
                                  liftEffect $ WebGL2.bindVertexArray xrWebGL2Context leftHandVAO
                                  liftEffect $ WebGL2.drawArrays xrWebGL2Context WebGL2.points 0 numberOfJointsPerHand

                                  liftEffect $ WebGL2.bindVertexArray xrWebGL2Context leftHandSkeletonVAO
                                  liftEffect $ WebGL2.drawElements xrWebGL2Context WebGL2.lines (length handSkeletonByJointIndices) WebGL2.unsignedShort 0

                                  liftEffect $ WebGL2.bindVertexArray xrWebGL2Context rightHandVAO
                                  liftEffect $ WebGL2.drawArrays xrWebGL2Context WebGL2.points 0 numberOfJointsPerHand

                                  liftEffect $ WebGL2.bindVertexArray xrWebGL2Context rightHandSkeletonVAO
                                  liftEffect $ WebGL2.drawElements xrWebGL2Context WebGL2.lines (length handSkeletonByJointIndices) WebGL2.unsignedShort 0

                                  updatedWorldState <- liftEffect $ Ref.read worldStateRef
                                  for_ (Map.values updatedWorldState.sceneObjects) \obj -> do
                                      case Map.lookup obj.geometryId updatedWorldState.gpuHandles of
                                          Nothing -> pure unit
                                          Just gpu -> do
                                              liftEffect $ WebGL2.uniformMatrix4fv xrWebGL2Context modelLocation false (composeModelMatrix obj.transform)
                                              liftEffect $ WebGL2.bindVertexArray xrWebGL2Context gpu.vao
                                              liftEffect $ WebGL2.drawElements xrWebGL2Context gpu.drawMode gpu.vertexCount WebGL2.unsignedShort 0 
                        case result of
                            Left err -> log err
                            Right _ -> pure unit
                        _ <- liftEffect $ WebXR.requestAnimationFrame xrSession tick
                        pure unit
                _ <- liftEffect $ WebXR.requestAnimationFrame xrSession tick
                pure unit

        -- [Adding event listener to the start experience button]
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
    -- [Logging any errors or messages that may have arised during the setup process]
    liftEffect $ case result of
        Left errorMessage -> log errorMessage
        Right message -> log message
