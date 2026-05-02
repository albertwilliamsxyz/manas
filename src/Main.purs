module Main where

import Prelude

import Control.Monad.Except (ExceptT, except, runExceptT)
import Data.Array (length, replicate, uncons, (!!))
import Data.Either (Either(..), note)
import Data.Foldable (for_)
import Data.Int.Bits ((.|.))
import Data.List as List
import Data.Map (Map, fromFoldable)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (toMaybe, notNull, null)
import Data.Number as Number
import Data.Tuple (Tuple(..), fst)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Aff.Class (liftAff)
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Console (log)
import Effect.Random (random)
import Effect.Ref as Ref
import Math.Geometry as Math.Geometry
import Math.Mat4 (Mat4)
import Math.Mat4 as Math.Mat4
import Math.Vec3 (Vec3)
import Math.Vec3 as Math.Vec3
import Primitives as Primitives
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
import WebGL2 (ShaderType(..), makeShader, makeProgram, makeBuffer, makeVertexArrayObject, findUniformLocation)
import WebGL2.Raw as WebGL2
import WebXR (makeXRWebGL2Compatible, isWebXRSessionModeSupported, requestSession, requestReferenceSpace)
import WebXR.Raw as WebXR


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
    -- Front face (z = +0.1), looking from +Z
    [ -0.1, -0.1,  0.1   -- 0
    ,  0.1, -0.1,  0.1   -- 1
    ,  0.1,  0.1,  0.1   -- 2
    , -0.1,  0.1,  0.1   -- 3
    -- Back face (z = -0.1), looking from -Z
    ,  0.1, -0.1, -0.1   -- 4
    , -0.1, -0.1, -0.1   -- 5
    , -0.1,  0.1, -0.1   -- 6
    ,  0.1,  0.1, -0.1   -- 7
    -- Right face (x = +0.1), looking from +X
    ,  0.1, -0.1,  0.1   -- 8
    ,  0.1, -0.1, -0.1   -- 9
    ,  0.1,  0.1, -0.1   -- 10
    ,  0.1,  0.1,  0.1   -- 11
    -- Left face (x = -0.1), looking from -X
    , -0.1, -0.1, -0.1   -- 12
    , -0.1, -0.1,  0.1   -- 13
    , -0.1,  0.1,  0.1   -- 14
    , -0.1,  0.1, -0.1   -- 15
    -- Top face (y = +0.1), looking from +Y
    , -0.1,  0.1,  0.1   -- 16
    ,  0.1,  0.1,  0.1   -- 17
    ,  0.1,  0.1, -0.1   -- 18
    , -0.1,  0.1, -0.1   -- 19
    -- Bottom face (y = -0.1), looking from -Y
    , -0.1, -0.1, -0.1   -- 20
    ,  0.1, -0.1, -0.1   -- 21
    ,  0.1, -0.1,  0.1   -- 22
    , -0.1, -0.1,  0.1   -- 23
    ]

cubeUVs :: Array Number
cubeUVs =
    -- Each face: bottomLeft (0,0), bottomRight (1,0), topRight (1,1), topLeft (0,1)
    [ 0.0, 0.0,  1.0, 0.0,  1.0, 1.0,  0.0, 1.0   -- front
    , 0.0, 0.0,  1.0, 0.0,  1.0, 1.0,  0.0, 1.0   -- back
    , 0.0, 0.0,  1.0, 0.0,  1.0, 1.0,  0.0, 1.0   -- right
    , 0.0, 0.0,  1.0, 0.0,  1.0, 1.0,  0.0, 1.0   -- left
    , 0.0, 0.0,  1.0, 0.0,  1.0, 1.0,  0.0, 1.0   -- top
    , 0.0, 0.0,  1.0, 0.0,  1.0, 1.0,  0.0, 1.0   -- bottom
    ]

cubeEdgeIndices :: Array Int
cubeEdgeIndices =
    [  0,  1,   1,  2,    2,  3,    3,  0   -- front
    ,  4,  5,   5,  6,    6,  7,    7,  4   -- back
    ,  8,  9,   9, 10,   10, 11,   11,  8   -- right
    , 12, 13,  13, 14,   14, 15,   15, 12   -- left
    , 16, 17,  17, 18,   18, 19,   19, 16   -- top
    , 20, 21,  21, 22,   22, 23,   23, 20   -- bottom
    ]

cubeTriangleIndices :: Array Int
cubeTriangleIndices =
    [  0,  1,  2,    0,  2,  3   -- front
    ,  4,  5,  6,    4,  6,  7   -- back
    ,  8,  9, 10,    8, 10, 11   -- right
    , 12, 13, 14,   12, 14, 15   -- left
    , 16, 17, 18,   16, 18, 19   -- top
    , 20, 21, 22,   20, 22, 23   -- bottom
    ]

-- [Vec3 Conversion]

readVec3At :: Primitives.Float32Array -> Int -> Effect Vec3
readVec3At arr index = do
  let offset = index * 3
  x <- Primitives.getAt arr offset
  y <- Primitives.getAt arr (offset + 1)
  z <- Primitives.getAt arr (offset + 2)
  pure (Math.Vec3.vec3 x y z)

-- [WebGL Shaders]

glslVersionDirective :: String
glslVersionDirective = "#version 300 es"

vertexShaderSourceCode :: String
vertexShaderSourceCode = glslVersionDirective <> """
in vec3 a_position;
in vec2 a_uv;
uniform mat4 u_projection;
uniform mat4 u_view;
uniform mat4 u_model;
out vec2 v_uv;
void main() {
  gl_Position = u_projection * u_view * u_model * vec4(a_position, 1.0);
  v_uv = a_uv;
  gl_PointSize = 10.0;
}
"""

fragmentShaderSourceCode :: String
fragmentShaderSourceCode = glslVersionDirective <> """
precision highp float;
in vec2 v_uv;
out vec4 outColor;
uniform vec4 u_color;
uniform bool u_useUV;
void main() {
  if (u_useUV) {
    outColor = vec4(v_uv, 0.0, 1.0);
  } else {
    outColor = u_color;
  }
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
    , uvs :: Array Number
    , edgeIndices :: Array Int
    , triangleIndices :: Array Int
    , topology :: Topology
    }

type Transform =
    { translation :: Mat4
    , rotation :: Mat4
    , scale :: Mat4
    }

-- [WebGL resource types]

type GPUHandle =
    { vao :: WebGL2.VertexArrayObject
    , vertexBuffer :: WebGL2.Buffer
    , uvBuffer :: WebGL2.Buffer
    , indexBuffer :: WebGL2.Buffer
    , drawMode :: Int
    , vertexCount :: Int
    }

-- [Input types]

data Handedness = LeftHand | RightHand

type HandInput = { jointPositions :: Primitives.Float32Array }

type Hands =
    { left :: Maybe HandInput
    , right :: Maybe HandInput
    }

type ControllerInput = 
    { position :: Primitives.Float32Array,
    orientation :: Primitives.Float32Array 
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

data InteractionMode
    = Observing
    | OneHandManipulate
        { hand :: Handedness
        , objectId :: SceneObjectId
        , grabOffset :: Vec3
        }
    | TwoHandManipulate
        { objectId :: SceneObjectId
        , initialMidpoint :: Vec3
        , initialDistance :: Number
        , initialDirection :: Vec3
        , initialScale :: Mat4
        , initialRotation :: Mat4
        , initialTranslation :: Mat4
        }

type HandState =
    { pinching :: Boolean
    , position :: Vec3
    }

type InteractionResult =
    { mode :: InteractionMode
    , sceneObjects :: Map SceneObjectId SceneObject
    , shouldSpawn :: Maybe { hand :: Handedness, position :: Vec3 }
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
    , interaction :: InteractionMode
    }


-- [Functions]

-- [Mathematics]

generateRandomTranslation :: Effect Mat4
generateRandomTranslation = do
    tx <- random
    ty <- random
    tz <- random
    pure $ Math.Mat4.translation (Math.Vec3.vec3 tx ty tz)

getVertex :: Array Number -> Int -> Vec3
getVertex vertices i =
    let offset = i * 3
        x = fromMaybe 0.0 (vertices !! offset)
        y = fromMaybe 0.0 (vertices !! (offset + 1))
        z = fromMaybe 0.0 (vertices !! (offset + 2))
    in Math.Vec3.vec3 x y z

rayMeshIntersect
    :: { origin :: Vec3, direction :: Vec3 }
    -> Mat4
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
                v0 = Math.Mat4.transformPoint modelMatrix (getVertex verts i0)
                v1 = Math.Mat4.transformPoint modelMatrix (getVertex verts i1)
                v2 = Math.Mat4.transformPoint modelMatrix (getVertex verts i2)
                hit = Math.Geometry.rayTriangleIntersect ray v0 v1 v2
            in case hit, closest of
                Just t, Nothing -> go (i + 1) (Just t)
                Just t, Just prev -> go (i + 1) (Just (min t prev))
                Nothing, _ -> go (i + 1) closest


-- [Utilities]

topologyToDrawMode :: Topology -> Int
topologyToDrawMode Points = WebGL2.points
topologyToDrawMode Lines = WebGL2.lines
topologyToDrawMode Triangles = WebGL2.triangles

addCubeToScene :: Mat4 -> WorldState -> WorldState
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
                , rotation: Math.Mat4.identity
                , scale: Math.Mat4.identity
                }
            }

uploadGeometry :: forall m. MonadEffect m => WebGL2.RenderingContext -> { positionLocation :: Int, uvLocation :: Int } -> Geometry -> ExceptT String m GPUHandle
uploadGeometry webGL2Context locations geometry = do
    let indices = case geometry.topology of
            Points -> []
            Lines -> geometry.edgeIndices
            Triangles -> geometry.triangleIndices
    vao <- makeVertexArrayObject webGL2Context
    vertexBuffer <- makeBuffer webGL2Context
    uvBuffer <- makeBuffer webGL2Context
    indexBuffer <- makeBuffer webGL2Context
    liftEffect $ WebGL2.bindVertexArray webGL2Context (notNull vao)
    liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer (notNull vertexBuffer)
    liftEffect $ WebGL2.bufferData webGL2Context WebGL2.arrayBuffer (Primitives.f32AsArrayBufferView (Primitives.float32Array geometry.vertices)) WebGL2.staticDraw
    liftEffect $ WebGL2.vertexAttribPointer webGL2Context locations.positionLocation baseNumberOfDimensions WebGL2.float false 0 0
    liftEffect $ WebGL2.enableVertexAttribArray webGL2Context locations.positionLocation
    liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer (notNull uvBuffer)
    liftEffect $ WebGL2.bufferData webGL2Context WebGL2.arrayBuffer (Primitives.f32AsArrayBufferView (Primitives.float32Array geometry.uvs)) WebGL2.staticDraw
    liftEffect $ WebGL2.vertexAttribPointer webGL2Context locations.uvLocation 2 WebGL2.float false 0 0
    liftEffect $ WebGL2.enableVertexAttribArray webGL2Context locations.uvLocation
    liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer (notNull indexBuffer)
    liftEffect $ WebGL2.bufferData webGL2Context WebGL2.elementArrayBuffer (Primitives.u16AsArrayBufferView (Primitives.uint16Array indices)) WebGL2.staticDraw
    liftEffect $ WebGL2.bindVertexArray webGL2Context null
    pure { vao
         , vertexBuffer
         , uvBuffer
         , indexBuffer
         , drawMode: topologyToDrawMode geometry.topology
         , vertexCount: length indices
         }

composeModelMatrix :: Transform -> Mat4
composeModelMatrix transform =
    Math.Mat4.multiply transform.translation
        (Math.Mat4.multiply transform.rotation transform.scale)

findHitObject
    :: { origin :: Vec3, direction :: Vec3 }
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
    :: Vec3
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
                objPos = Math.Mat4.translationOf modelMatrix
                dist = Math.Vec3.distance pinchPoint objPos
                objScale = Math.Mat4.scaleOf modelMatrix
                adjustedRadius = grabRadius * objScale
            in if dist < adjustedRadius
                then case acc of
                    Nothing -> go rest (Just (Tuple objId dist))
                    Just (Tuple _ prevDist)
                        | dist < prevDist -> go rest (Just (Tuple objId dist))
                        | otherwise -> go rest acc
                else go rest acc

updateInteraction 
    :: HandState
    -> HandState
    -> Map SceneObjectId SceneObject
    -> InteractionMode
    -> InteractionResult
updateInteraction left right sceneObjects mode = case mode of
    Observing -> case left.pinching, right.pinching of
        true, _ -> tryGrab LeftHand left.position
        _, true -> tryGrab RightHand right.position
        _, _ -> idle
    OneHandManipulate state -> case state.hand of
        LeftHand 
            | not left.pinching -> idle
            | right.pinching -> enterTwoHand left.position right.position state
            | otherwise -> applyOneHand left.position state
        RightHand
            | not right.pinching -> idle
            | left.pinching -> enterTwoHand left.position right.position state
            | otherwise -> applyOneHand right.position state
    TwoHandManipulate state -> case left.pinching, right.pinching of
        false, false -> idle
        true, false ->
            case Map.lookup state.objectId sceneObjects of
                Just obj ->
                    let objPos = Math.Mat4.translationOf (composeModelMatrix obj.transform)
                    in { mode: OneHandManipulate { hand: LeftHand, objectId: state.objectId, grabOffset: Math.Vec3.sub left.position objPos }
                       , sceneObjects
                       , shouldSpawn: Nothing
                       }
                Nothing -> idle
        false, true ->
            case Map.lookup state.objectId sceneObjects of
                Just obj ->
                    let objPos = Math.Mat4.translationOf (composeModelMatrix obj.transform)
                    in { mode: OneHandManipulate { hand: RightHand, objectId: state.objectId, grabOffset: Math.Vec3.sub right.position objPos }
                       , sceneObjects
                       , shouldSpawn: Nothing
                       }
                Nothing -> idle
        true, true -> applyTwoHand left.position right.position state
    where
    idle = { mode: Observing, sceneObjects, shouldSpawn: Nothing }
    tryGrab hand pos =
        case findNearestObject pos sceneObjects of
            Just objId -> case Map.lookup objId sceneObjects of
                Just obj ->
                    let objPos = Math.Mat4.translationOf (composeModelMatrix obj.transform)
                    in { mode: OneHandManipulate { hand, objectId: objId, grabOffset: Math.Vec3.sub pos objPos }
                       , sceneObjects
                       , shouldSpawn: Nothing
                       }
                Nothing -> idle
            Nothing -> { mode: Observing, sceneObjects, shouldSpawn: Just { hand, position: pos } }
    applyOneHand pos state =
        let newPos = Math.Vec3.sub pos state.grabOffset
            newSceneObjects = Map.update (\obj -> Just obj { transform = obj.transform { translation = Math.Mat4.translation newPos } }) state.objectId sceneObjects
        in { mode: OneHandManipulate state, sceneObjects: newSceneObjects, shouldSpawn: Nothing }
    enterTwoHand leftPos rightPos state =
        case Map.lookup state.objectId sceneObjects of
            Just obj ->
                { mode: TwoHandManipulate
                    { objectId: state.objectId
                    , initialMidpoint: Math.Vec3.midpoint leftPos rightPos
                    , initialDistance: Math.Vec3.distance leftPos rightPos
                    , initialDirection: fromMaybe Math.Vec3.zero (Math.Vec3.normalize (Math.Vec3.sub rightPos leftPos))
                    , initialScale: obj.transform.scale
                    , initialRotation: obj.transform.rotation
                    , initialTranslation: obj.transform.translation
                    }
                , sceneObjects
                , shouldSpawn: Nothing
                }
            Nothing -> idle
    applyTwoHand leftPos rightPos state =
        let currentMidpoint = Math.Vec3.midpoint leftPos rightPos
            currentDistance = Math.Vec3.distance leftPos rightPos
            scaleFactor = currentDistance / state.initialDistance

            initialPos = Math.Mat4.translationOf state.initialTranslation
            midpointDelta = Math.Vec3.sub currentMidpoint state.initialMidpoint
            newTranslation = Math.Mat4.translation (Math.Vec3.add initialPos midpointDelta)

            newScale = Math.Mat4.scale scaleFactor

            currentDirection = fromMaybe Math.Vec3.zero (Math.Vec3.normalize (Math.Vec3.sub rightPos leftPos))
            rotationAxis = Math.Vec3.cross state.initialDirection currentDirection
            axisLength = Math.Vec3.dot rotationAxis rotationAxis
            cosAngle = Math.Vec3.dot state.initialDirection currentDirection
            newRotation = if axisLength < 0.000001
                then state.initialRotation
                else Math.Mat4.multiply
                    (Math.Mat4.axisAngleRotation (fromMaybe Math.Vec3.zero (Math.Vec3.normalize rotationAxis)) cosAngle (Number.sqrt axisLength))
                    state.initialRotation

            newSceneObjects = Map.update (\obj -> Just obj
                { transform = obj.transform
                    { translation = newTranslation
                    , scale = newScale
                    , rotation = newRotation
                    }
                }) state.objectId sceneObjects
        in { mode: TwoHandManipulate state, sceneObjects: newSceneObjects, shouldSpawn: Nothing }


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
        nullableWebGL2Context <- liftEffect $ WebGL2.getContext applicationCanvasAsElement
        webGL2Context <- except $ note "WebGL2 not supported" (toMaybe nullableWebGL2Context)

        vertexShader <- makeShader webGL2Context VertexShader vertexShaderSourceCode
        fragmentShader <- makeShader webGL2Context FragmentShader fragmentShaderSourceCode

        program <- makeProgram webGL2Context { vertex: vertexShader, fragment: fragmentShader }
        liftEffect $ WebGL2.useProgram webGL2Context program
        liftEffect $ WebGL2.enable webGL2Context WebGL2.depthTest

        -- [Getting the WebGL location of shader attributes and uniforms, and setting up initial values]
        positionLocation <- liftEffect $ WebGL2.getAttribLocation webGL2Context program "a_position"
        when (positionLocation == -1) $ except $ Left "Unable to get the location of the position attribute"

        uvLocation <- liftEffect $ WebGL2.getAttribLocation webGL2Context program "a_uv"
        when (uvLocation == -1) $ except $ Left "Unable to get the location of the uv attribute"

        projectionLocation <- findUniformLocation webGL2Context program "u_projection"
        liftEffect $ WebGL2.uniformMatrix4fv webGL2Context projectionLocation false (Math.Mat4.toFloat32Array Math.Mat4.identity)

        viewLocation <- findUniformLocation webGL2Context program "u_view"
        liftEffect $ WebGL2.uniformMatrix4fv webGL2Context viewLocation false (Math.Mat4.toFloat32Array Math.Mat4.identity)

        modelLocation <- findUniformLocation webGL2Context program "u_model"
        liftEffect $ WebGL2.uniformMatrix4fv webGL2Context modelLocation false (Math.Mat4.toFloat32Array Math.Mat4.identity)

        colorLocation <- findUniformLocation webGL2Context program "u_color"
        liftEffect $ WebGL2.uniform4fv webGL2Context colorLocation (Primitives.float32Array [0.0, 0.8, 0.0, 1.0])

        useUVLocation <- findUniformLocation webGL2Context program "u_useUV"
        liftEffect $ WebGL2.uniform1i webGL2Context useUVLocation 0

        let cubeGeometryId = GeometryId "cube"
            cubeGeometry =
                { vertices: cubeVertices
                , uvs: cubeUVs
                , edgeIndices: cubeEdgeIndices
                , triangleIndices: cubeTriangleIndices
                , topology: Triangles
                }

        cubeGPUHandle <- uploadGeometry webGL2Context { positionLocation, uvLocation } cubeGeometry

        cubePosition <- liftEffect $ generateRandomTranslation
        let cubeSceneObjectId = SceneObjectId "cube-instance-1"
            cubeSceneObject =
                { geometryId: cubeGeometryId
                , transform:
                    { translation: cubePosition
                    , rotation: Math.Mat4.identity
                    , scale: Math.Mat4.identity
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
                , interaction: Observing
                }

        worldStateRef <- liftEffect $ Ref.new initialWorldState

        handSkeletonJointIndicesBuffer <- makeBuffer webGL2Context
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer (notNull handSkeletonJointIndicesBuffer)
        liftEffect $ WebGL2.bufferData webGL2Context WebGL2.elementArrayBuffer (Primitives.u16AsArrayBufferView (Primitives.uint16Array handSkeletonByJointIndices)) WebGL2.staticDraw

        leftHandVAO <- makeVertexArrayObject webGL2Context
        leftHandBuffer <- makeBuffer webGL2Context
        liftEffect $ WebGL2.bindVertexArray webGL2Context (notNull leftHandVAO)
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer (notNull leftHandBuffer)
        liftEffect $ WebGL2.bufferData webGL2Context WebGL2.arrayBuffer (
            Primitives.f32AsArrayBufferView (Primitives.float32Array (replicate (numberOfJointsPerHand * baseNumberOfDimensions) 0.0))
        ) WebGL2.dynamicDraw
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
        liftEffect $ WebGL2.bindVertexArray webGL2Context null

        leftHandSkeletonVAO <- makeVertexArrayObject webGL2Context
        liftEffect $ WebGL2.bindVertexArray webGL2Context (notNull leftHandSkeletonVAO)
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer (notNull leftHandBuffer)
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer (notNull handSkeletonJointIndicesBuffer)
        liftEffect $ WebGL2.bindVertexArray webGL2Context null

        rightHandVAO <- makeVertexArrayObject webGL2Context
        rightHandBuffer <- makeBuffer webGL2Context
        liftEffect $ WebGL2.bindVertexArray webGL2Context (notNull rightHandVAO)
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer (notNull rightHandBuffer)
        liftEffect $ WebGL2.bufferData webGL2Context WebGL2.arrayBuffer (
            Primitives.f32AsArrayBufferView (Primitives.float32Array (replicate (numberOfJointsPerHand * baseNumberOfDimensions) 0.0))
        ) WebGL2.dynamicDraw
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
        liftEffect $ WebGL2.bindVertexArray webGL2Context null

        rightHandSkeletonVAO <- makeVertexArrayObject webGL2Context
        liftEffect $ WebGL2.bindVertexArray webGL2Context (notNull rightHandSkeletonVAO)
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer (notNull rightHandBuffer)
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer (notNull handSkeletonJointIndicesBuffer)
        liftEffect $ WebGL2.bindVertexArray webGL2Context null

        -- [Starting the experience on button click and running the main loop]
        let runExperience :: Window -> Navigator -> WebGL2.RenderingContext -> Aff (Either String Unit)
            runExperience xrWin xrNav xrWebGL2Context = runExceptT do
                -- [Getting the XR-related resources]
                nullableXRSystem <- liftEffect $ WebXR.getXRSystem xrNav
                xrSystem <- except $ note "WebXR not supported" (toMaybe nullableXRSystem)

                isWebXRSessionModeSupported <- liftAff $ isWebXRSessionModeSupported xrSystem "immersive-ar"
                unless isWebXRSessionModeSupported $ except $ Left "WebXR session mode not supported"
                liftAff $ makeXRWebGL2Compatible xrWebGL2Context

                xrSession <- liftAff $ requestSession xrSystem "immersive-ar" { requiredFeatures: ["hand-tracking"] }
                xrGLLayer <- liftEffect $ WebXR.createXRWebGLLayer xrWin xrSession xrWebGL2Context
                liftEffect $ WebXR.updateRenderState xrSession { baseLayer: xrGLLayer }

                referenceSpace <- liftAff $ requestReferenceSpace xrSession "local"

                let leftHandVertices = Primitives.float32Array (replicate (numberOfHandJointDimensions) 0.0)
                    rightHandVertices = Primitives.float32Array (replicate (numberOfHandJointDimensions) 0.0)
                    identityFloat32Array = Math.Mat4.toFloat32Array Math.Mat4.identity
                    skeletonIndexCount = length handSkeletonByJointIndices

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
                                        liftEffect $ Primitives.copyInto verticesReference positionArray offset
                                    case jointResult of
                                        Left err -> liftEffect $ log $ "Joint Loop Error (" <> joint.name <> "): " <> err
                                        Right _ -> pure unit

                            liftEffect $ WebGL2.bindBuffer xrWebGL2Context WebGL2.arrayBuffer (notNull leftHandBuffer)
                            liftEffect $ WebGL2.bufferSubData xrWebGL2Context WebGL2.arrayBuffer 0 (Primitives.f32AsArrayBufferView leftHandVertices)
                            liftEffect $ WebGL2.bindBuffer xrWebGL2Context WebGL2.arrayBuffer (notNull rightHandBuffer)
                            liftEffect $ WebGL2.bufferSubData xrWebGL2Context WebGL2.arrayBuffer 0 (Primitives.f32AsArrayBufferView rightHandVertices)

                            -- [Managing gestures]
                            let maybeIndexFingerTipIndex = Map.lookup "index-finger-tip" handJointIndicesByName
                            let maybeThumbTipIndex = Map.lookup "thumb-tip" handJointIndicesByName
                            indexFingerTipIndex <- except $ note "No index-finger-tip index" maybeIndexFingerTipIndex
                            thumbTipIndex <- except $ note "No thumb-tip index" maybeThumbTipIndex
                            leftIndexFingerTipPosition <- liftEffect $ readVec3At leftHandVertices indexFingerTipIndex
                            leftThumbTipPosition <- liftEffect $ readVec3At leftHandVertices thumbTipIndex
                            let leftThumbIndexDistance = Math.Vec3.distance leftIndexFingerTipPosition leftThumbTipPosition
                            let leftIsPinching = leftThumbIndexDistance < pinchThreshold

                            rightIndexFingerTipPosition <- liftEffect $ readVec3At rightHandVertices indexFingerTipIndex
                            rightThumbTipPosition <- liftEffect $ readVec3At rightHandVertices thumbTipIndex
                            let rightThumbIndexDistance = Math.Vec3.distance rightIndexFingerTipPosition rightThumbTipPosition
                            let rightIsPinching = rightThumbIndexDistance < pinchThreshold

                            worldState <- liftEffect $ Ref.read worldStateRef

                            let leftHand = { pinching: leftIsPinching, position: leftIndexFingerTipPosition }
                            let rightHand = { pinching: rightIsPinching, position: rightIndexFingerTipPosition }
                            let interactionResult = updateInteraction leftHand rightHand worldState.sceneObjects worldState.interaction

                            liftEffect $ Ref.modify_ (\ws -> ws 
                                { sceneObjects = interactionResult.sceneObjects
                                , interaction = interactionResult.mode
                                }) worldStateRef

                            case interactionResult.shouldSpawn of
                                Just spawn -> do
                                    let translationMatrix = Math.Mat4.translation spawn.position
                                    liftEffect $ Ref.modify_ (addCubeToScene translationMatrix) worldStateRef
                                Nothing -> pure unit

                            -- [Managing rendering]
                            framebuffer <- liftEffect $ WebXR.getFramebuffer xrGLLayer
                            liftEffect $ WebGL2.bindFramebuffer xrWebGL2Context WebGL2.framebuffer (notNull framebuffer)
                            liftEffect $ WebGL2.clearColor xrWebGL2Context 0.0 0.0 0.0 1.0
                            liftEffect $ WebGL2.clear xrWebGL2Context (WebGL2.colorBufferBit .|. WebGL2.depthBufferBit)

                            nullableViewerPose <- liftEffect $ WebXR.getViewerPose frame referenceSpace
                            case toMaybe nullableViewerPose of
                              Nothing -> pure unit
                              Just viewerPose -> do
                                views <- liftEffect $ WebXR.getViews viewerPose
                                updatedWorldState <- liftEffect $ Ref.read worldStateRef
                                let asDrawable obj = case Map.lookup obj.geometryId updatedWorldState.gpuHandles of
                                      Nothing -> Nothing
                                      Just gpu -> Just
                                        { gpu
                                        , modelMatrix: Math.Mat4.toFloat32Array (composeModelMatrix obj.transform)
                                        }
                                    drawables = List.mapMaybe asDrawable (Map.values updatedWorldState.sceneObjects)
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
                                  liftEffect $ WebGL2.uniformMatrix4fv xrWebGL2Context modelLocation false identityFloat32Array

                                  -- [Rendering hands and skeleton with uniform color]
                                  liftEffect $ WebGL2.uniform1i xrWebGL2Context useUVLocation 0

                                  liftEffect $ WebGL2.bindVertexArray xrWebGL2Context (notNull leftHandVAO)
                                  liftEffect $ WebGL2.drawArrays xrWebGL2Context WebGL2.points 0 numberOfJointsPerHand

                                  liftEffect $ WebGL2.bindVertexArray xrWebGL2Context (notNull leftHandSkeletonVAO)
                                  liftEffect $ WebGL2.drawElements xrWebGL2Context WebGL2.lines skeletonIndexCount WebGL2.unsignedShort 0

                                  liftEffect $ WebGL2.bindVertexArray xrWebGL2Context (notNull rightHandVAO)
                                  liftEffect $ WebGL2.drawArrays xrWebGL2Context WebGL2.points 0 numberOfJointsPerHand

                                  liftEffect $ WebGL2.bindVertexArray xrWebGL2Context (notNull rightHandSkeletonVAO)
                                  liftEffect $ WebGL2.drawElements xrWebGL2Context WebGL2.lines skeletonIndexCount WebGL2.unsignedShort 0

                                  -- [Rendering scene objects with UV-as-color debug]
                                  liftEffect $ WebGL2.uniform1i xrWebGL2Context useUVLocation 1

                                  for_ drawables \drawable -> do
                                      liftEffect $ WebGL2.uniformMatrix4fv xrWebGL2Context modelLocation false drawable.modelMatrix
                                      liftEffect $ WebGL2.bindVertexArray xrWebGL2Context (notNull drawable.gpu.vao)
                                      liftEffect $ WebGL2.drawElements xrWebGL2Context drawable.gpu.drawMode drawable.gpu.vertexCount WebGL2.unsignedShort 0
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
        startButtonAsHtmlButtonElement <- except $ note "Start experience button could not be converted to HTMLButtonElement" (HTMLButtonElement.fromElement startButtonElement)
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
