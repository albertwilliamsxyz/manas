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
import Data.Nullable (toMaybe, notNull, null)
import Data.Number as Number
import Data.Tuple (Tuple(..), fst)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
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
import WebGL2 (ShaderType(..), makeShader, makeProgram)
import WebGL2.Raw as WebGL2
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
    { translation :: Mat4
    , rotation :: Mat4
    , scale :: Mat4
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

uploadGeometry :: WebGL2.RenderingContext -> Int -> Geometry -> ExceptT String Effect GPUHandle
uploadGeometry webGL2Context positionLocation geometry = do
    nullableVAO <- liftEffect $ WebGL2.createVertexArray webGL2Context
    vao <- except $ note "VAO could not be created" (toMaybe nullableVAO)
    nullableVertexBuffer <- liftEffect $ WebGL2.createBuffer webGL2Context
    vertexBuffer <- except $ note "Vertex buffer could not be created" (toMaybe nullableVertexBuffer)
    nullableIndexBuffer <- liftEffect $ WebGL2.createBuffer webGL2Context
    indexBuffer <- except $ note "Index buffer could not be created" (toMaybe nullableIndexBuffer)
    liftEffect $ WebGL2.bindVertexArray webGL2Context (notNull vao)
    liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer vertexBuffer
    liftEffect $ WebGL2.bufferData webGL2Context WebGL2.arrayBuffer (Primitives.f32AsArrayBufferView (Primitives.float32Array geometry.vertices)) WebGL2.staticDraw
    liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer indexBuffer
    liftEffect $ WebGL2.bufferData webGL2Context WebGL2.elementArrayBuffer (Primitives.u16AsArrayBufferView (Primitives.uint16Array geometry.edgeIndices)) WebGL2.staticDraw
    liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
    liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
    liftEffect $ WebGL2.bindVertexArray webGL2Context null
    pure { vao
         , vertexBuffer
         , indexBuffer
         , drawMode: topologyToDrawMode geometry.topology
         , vertexCount: length geometry.edgeIndices
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
        -- Note: Here we're interfacing with the DOM to get the canvas element and set up WebGL2.
        win <- liftEffect window
        doc <- liftEffect $ document win
        nav <- liftEffect $ navigator win

        -- Note: Here we're reading the applicationCanvas
        maybeApplicationCanvas <- liftEffect $ getElementById "application" (HTMLDocument.toNonElementParentNode doc)
        applicationCanvas <- except $ note "applicationCanvas not found" maybeApplicationCanvas
        applicationCanvasAsElement <- except $ note "applicationCanvas could not be converted to HTMLCanvasElement" (HTMLCanvasElement.fromElement applicationCanvas)

        -- [Setting up WebGL2 context and resources]
        nullableWebGL2Context <- liftEffect $ WebGL2.getContext applicationCanvasAsElement
        webGL2Context <- except $ note "WebGL2 not supported" (toMaybe nullableWebGL2Context)

        -- Question: I want to analyze the totality of this piece of code, and extract it into its own function, I was thinking about 1) creating a function that abstracts what is common between this and the next piece, and 2) creating its own function to just clean up this function a little more. See which layers are involved, the validations, etc
        vertexShader <- makeShader webGL2Context VertexShader vertexShaderSourceCode

        -- Question: I want to analyze the totality of this piece of code, and extract it into its own function, see prev question
        fragmentShader <- makeShader webGL2Context FragmentShader fragmentShaderSourceCode

        program <- makeProgram webGL2Context { vertex: vertexShader, fragment: fragmentShader }
        liftEffect $ WebGL2.useProgram webGL2Context program

        -- Note: This is part of the WebGL2 setup
        liftEffect $ WebGL2.enable webGL2Context WebGL2.depthTest

        -- [Getting the WebGL location of shader attributes and uniforms, and setting up initial values]
        -- Note: All this block, and getting all the locations, originally was something that I thought I could put into a function to clean this main a little, but then I realized that I don't want to  abstract these details, because what could I return a tuple? And the typing does not gimme enough info to infer that the location is for this this and that. Also, some validate in one way, some in another. If I created a function it would be called something monstruous such as get maybe position, projection, view and model locations... Although we might follow our progression and through common find patterns, the naming (it already has some naming to it) a type expressing the idea we want to abstract and if all is good find the right abstraction
        positionLocation <- liftEffect $ WebGL2.getAttribLocation webGL2Context program "a_position"
        _ <- if positionLocation == -1
            then except $ Left "Unable to get the location of the position attribute"
            else except $ Right "Position attribute location obtained successfully"

        nullableProjectionLocation <- liftEffect $ WebGL2.getUniformLocation webGL2Context program "u_projection"
        projectionLocation <- except $ note "Unable to get the location of the projection uniform" (toMaybe nullableProjectionLocation)
        liftEffect $ WebGL2.uniformMatrix4fv webGL2Context projectionLocation false (Math.Mat4.toFloat32Array Math.Mat4.identity)

        nullableViewLocation <- liftEffect $ WebGL2.getUniformLocation webGL2Context program "u_view"
        viewLocation <- except $ note "Unable to get the location of the view uniform" (toMaybe nullableViewLocation)
        liftEffect $ WebGL2.uniformMatrix4fv webGL2Context viewLocation false (Math.Mat4.toFloat32Array Math.Mat4.identity)

        nullableModelLocation <- liftEffect $ WebGL2.getUniformLocation webGL2Context program "u_model"
        modelLocation <- except $ note "Unable to get the location of the model uniform" (toMaybe nullableModelLocation)
        liftEffect $ WebGL2.uniformMatrix4fv webGL2Context modelLocation false (Math.Mat4.toFloat32Array Math.Mat4.identity)

        nullableColorLocation <- liftEffect $ WebGL2.getUniformLocation webGL2Context program "u_color"
        colorLocation <- except $ note "Unable to get the location of the color uniform" (toMaybe nullableColorLocation)
        liftEffect $ WebGL2.uniform4fv webGL2Context colorLocation (Primitives.float32Array [0.0, 0.8, 0.0, 1.0])

        -- [WIP: Abstracting new structure]
        -- Note: Here I want to add a new list of models, not just a cube, and then be able to select which one I want to spawn :P I know I'm going to need some text maybe or some other way to select the model (even rendering them in a palette for example), I also want to start thinking about the scene as a graph, but without losing performance, can we use lists or arrays? Are they more performant?
        let cubeGeometryId = GeometryId "cube"
            cubeGeometry =
                { vertices: cubeVertices
                , edgeIndices: cubeEdgeIndices
                ,triangleIndices: cubeTriangleIndices
                , topology: Lines
                }

        cubeGPUHandleResult <- liftEffect $ runExceptT $ uploadGeometry webGL2Context positionLocation cubeGeometry
        cubeGPUHandle <- except cubeGPUHandleResult

        -- Note: Here we would see a change when we change the function generateRandomXYZ
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

        -- Note: I want to audit the initial world state
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

        -- Note: I don't know if I want my functions to be aware of the world state, maybe there are some that have to live at this level of abstraction, but I don't know. Also, at which point does my engine become general enough to brand it as some sort of blender, model viewer, or whatever, and not just an experience? I guess when we have a scene graph, a way to import models, lights, materials, etc. But maybe we can start adding some of these features and see how it evolves, maybe we find that we need to refactor some of the code to make it more general, or maybe we find that it's already general enough and we just need to add features on top of it. I guess we will see
        worldStateRef <- liftEffect $ Ref.new initialWorldState

        -- Note: How do this differs and compares to the geometry upload generally? Beyond what we've analyzed
        nullableHandSkeletonJointIndicesBuffer <- liftEffect $ WebGL2.createBuffer webGL2Context
        handSkeletonJointIndicesBuffer <- except $ note "Hand skeleton joint indices buffer could not be created" (toMaybe nullableHandSkeletonJointIndicesBuffer)
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer handSkeletonJointIndicesBuffer
        liftEffect $ WebGL2.bufferData webGL2Context WebGL2.elementArrayBuffer (Primitives.u16AsArrayBufferView (Primitives.uint16Array handSkeletonByJointIndices)) WebGL2.staticDraw

        nullableLeftHandVAO <- liftEffect $ WebGL2.createVertexArray webGL2Context
        leftHandVAO <- except $ note "Left hand VAO could not be created" (toMaybe nullableLeftHandVAO)
        nullableLeftHandBuffer <- liftEffect $ WebGL2.createBuffer webGL2Context
        leftHandBuffer <- except $ note "Left hand buffer could not be created" (toMaybe nullableLeftHandBuffer)
        liftEffect $ WebGL2.bindVertexArray webGL2Context (notNull leftHandVAO)
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer leftHandBuffer
        liftEffect $ WebGL2.bufferData webGL2Context WebGL2.arrayBuffer (
            Primitives.f32AsArrayBufferView (Primitives.float32Array (replicate (numberOfJointsPerHand * baseNumberOfDimensions) 0.0))
        ) WebGL2.dynamicDraw
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
        liftEffect $ WebGL2.bindVertexArray webGL2Context null

        nullableLeftHandSkeletonVAO <- liftEffect $ WebGL2.createVertexArray webGL2Context
        leftHandSkeletonVAO <- except $ note "Left hand skeleton VAO could not be created" (toMaybe nullableLeftHandSkeletonVAO)
        liftEffect $ WebGL2.bindVertexArray webGL2Context (notNull leftHandSkeletonVAO)
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer leftHandBuffer
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer handSkeletonJointIndicesBuffer
        liftEffect $ WebGL2.bindVertexArray webGL2Context null

        nullableRightHandVAO <- liftEffect $ WebGL2.createVertexArray webGL2Context
        rightHandVAO <- except $ note "Right hand VAO could not be created" (toMaybe nullableRightHandVAO)
        nullableRightHandBuffer <- liftEffect $ WebGL2.createBuffer webGL2Context
        rightHandBuffer <- except $ note "Right hand buffer could not be created" (toMaybe nullableRightHandBuffer)
        liftEffect $ WebGL2.bindVertexArray webGL2Context (notNull rightHandVAO)
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer rightHandBuffer
        liftEffect $ WebGL2.bufferData webGL2Context WebGL2.arrayBuffer (
            Primitives.f32AsArrayBufferView (Primitives.float32Array (replicate (numberOfJointsPerHand * baseNumberOfDimensions) 0.0))
        ) WebGL2.dynamicDraw
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
        liftEffect $ WebGL2.bindVertexArray webGL2Context null

        nullableRightHandSkeletonVAO <- liftEffect $ WebGL2.createVertexArray webGL2Context
        rightHandSkeletonVAO <- except $ note "Right hand skeleton VAO could not be created" (toMaybe nullableRightHandSkeletonVAO)
        liftEffect $ WebGL2.bindVertexArray webGL2Context (notNull rightHandSkeletonVAO)
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.arrayBuffer rightHandBuffer
        liftEffect $ WebGL2.vertexAttribPointer webGL2Context positionLocation baseNumberOfDimensions WebGL2.float false 0 0
        liftEffect $ WebGL2.enableVertexAttribArray webGL2Context positionLocation
        liftEffect $ WebGL2.bindBuffer webGL2Context WebGL2.elementArrayBuffer handSkeletonJointIndicesBuffer
        liftEffect $ WebGL2.bindVertexArray webGL2Context null

        -- Note: To this point, I think all is just setup, and at the end we have is... a world state? And some resources ready to be used in the experience, but the experience is not running yet, we need to start the XR session and then we can start rendering and updating the world state based on the inputs and interactions
        -- [Starting the experience on button click and running the main loop]
        let runExperience :: Window -> Navigator -> WebGL2.RenderingContext -> Aff (Either String Unit)
            runExperience xrWin xrNav xrWebGL2Context = runExceptT do
                -- [Getting the XR-related resources]
                -- Note: Here we're interfacing with the WebXR API to get the XR system, check for session support, request a session, and set up the rendering loop. This is where we start to see the experience come to life, as we manage the XR session and handle the input data from hand tracking to update our world state and render the scene accordingly.
                nullableXRSystem <- liftEffect $ WebXR.getXRSystem xrNav
                xrSystem <- except $ note "WebXR not supported" (toMaybe nullableXRSystem)

                -- Note: Can we just extract run experience into its own experience? I think it might receive a WorldState and then returning the runExperience function itself, but I don't want to do this directly, I think the wisest way to approach it is to list all the references from outside this scope, and encapsulate them within the world state.
                isWebXRSessionModeSupported <- liftAff $ WebXR.isWebXRSessionModeSupported xrSystem "immersive-ar"
                _ <- if not isWebXRSessionModeSupported
                    then except $ Left "WebXR session mode not supported"
                    else except $ Right "WebXR session mode supported"
                liftAff $ WebXR.makeXRWebGL2Compatible xrWebGL2Context

                -- Note: I want my types to be honest here I've been declaring a lot of things explicitly as I use them but I want to explore with other types of experiences
                xrSession <- liftAff $ WebXR.requestSession xrSystem "immersive-ar" { requiredFeatures: ["hand-tracking"] }
                xrGLLayer <- liftEffect $ WebXR.createXRWebGLLayer xrWin xrSession xrWebGL2Context
                liftEffect $ WebXR.updateRenderState xrSession { baseLayer: xrGLLayer }

                -- Note: I would like to move within a boundary, right now I can only use the app in a single position.
                referenceSpace <- liftAff $ WebXR.requestReferenceSpace xrSession "local"

                -- Note: Isn't this part of the world state?
                let leftHandVertices = Primitives.float32Array (replicate (numberOfHandJointDimensions) 0.0)
                    rightHandVertices = Primitives.float32Array (replicate (numberOfHandJointDimensions) 0.0)

                -- [Callback for tick updates from the XR session]
                -- Note: Maybe we have to move this outside the runExperience function, but then, how do we know which function calls what and how is this different from the theoretical tick I'm think of that is only involved with the world state update? And what if I wanted to run this from a browser to for example see what I'm projecting as if it was a class, but for people who don't have VR? I don't want my logic to be here because I might have to declare another way to tick the experience, here also we're just capturing the input, translating it to world state, and then rendering based on the world state, and capturing gestures, etc, etc
                let tick :: WebXR.XRFrameRequestCallback
                    tick _ frame = do
                        result <- runExceptT do
                            -- [Managing hand tracking data]
                            -- Note: This might be a function in its own layer
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

                            liftEffect $ WebGL2.bindBuffer xrWebGL2Context WebGL2.arrayBuffer leftHandBuffer
                            liftEffect $ WebGL2.bufferSubData xrWebGL2Context WebGL2.arrayBuffer 0 (Primitives.f32AsArrayBufferView leftHandVertices)
                            liftEffect $ WebGL2.bindBuffer xrWebGL2Context WebGL2.arrayBuffer rightHandBuffer
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
                                  liftEffect $ WebGL2.uniformMatrix4fv xrWebGL2Context modelLocation false (Math.Mat4.toFloat32Array Math.Mat4.identity)

                                  -- [Rendering]
                                  liftEffect $ WebGL2.bindVertexArray xrWebGL2Context (notNull leftHandVAO)
                                  liftEffect $ WebGL2.drawArrays xrWebGL2Context WebGL2.points 0 numberOfJointsPerHand

                                  liftEffect $ WebGL2.bindVertexArray xrWebGL2Context (notNull leftHandSkeletonVAO)
                                  liftEffect $ WebGL2.drawElements xrWebGL2Context WebGL2.lines (length handSkeletonByJointIndices) WebGL2.unsignedShort 0

                                  liftEffect $ WebGL2.bindVertexArray xrWebGL2Context (notNull rightHandVAO)
                                  liftEffect $ WebGL2.drawArrays xrWebGL2Context WebGL2.points 0 numberOfJointsPerHand

                                  liftEffect $ WebGL2.bindVertexArray xrWebGL2Context (notNull rightHandSkeletonVAO)
                                  liftEffect $ WebGL2.drawElements xrWebGL2Context WebGL2.lines (length handSkeletonByJointIndices) WebGL2.unsignedShort 0

                                  updatedWorldState <- liftEffect $ Ref.read worldStateRef
                                  for_ (Map.values updatedWorldState.sceneObjects) \obj -> do
                                      case Map.lookup obj.geometryId updatedWorldState.gpuHandles of
                                          Nothing -> pure unit
                                          Just gpu -> do
                                              liftEffect $ WebGL2.uniformMatrix4fv xrWebGL2Context modelLocation false (Math.Mat4.toFloat32Array (composeModelMatrix obj.transform))
                                              liftEffect $ WebGL2.bindVertexArray xrWebGL2Context (notNull gpu.vao)
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
