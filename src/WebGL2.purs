module WebGL2 where

import Prelude

import Control.Promise (Promise, toAffE)
import Data.Nullable (Nullable)
import Effect (Effect)
import Effect.Aff (Aff)
import Web.HTML.HTMLCanvasElement (HTMLCanvasElement)


foreign import data Float32Array :: Type
foreign import float32Array :: forall a. a -> Float32Array

foreign import data RenderingContext :: Type
foreign import createContext
    :: HTMLCanvasElement -> Effect (Nullable RenderingContext)

type ShaderType = Int
vertexShader :: ShaderType
vertexShader = 0x8B31
fragmentShader :: ShaderType 
fragmentShader = 0x8B30

compileStatus :: Int
compileStatus = 0x8B81
linkStatus :: Int
linkStatus = 0x8B82


foreign import data Shader :: Type
type ShaderParameter = Boolean

foreign import createShader
    :: RenderingContext -> ShaderType -> Effect (Nullable Shader)
foreign import shaderSource
    :: RenderingContext -> Shader -> String -> Effect Unit
foreign import compileShader
    :: RenderingContext -> Shader -> Effect Unit
foreign import getShaderParameter
    :: RenderingContext -> Shader -> Int -> Effect ShaderParameter
foreign import getShaderInfoLog
    :: RenderingContext -> Shader -> Effect (Nullable String)
foreign import deleteShader
    :: RenderingContext -> Shader -> Effect Unit


foreign import data Program :: Type
type ProgramParameter = Boolean

foreign import createProgram
    :: RenderingContext -> Effect (Nullable Program)
foreign import attachShader
    :: RenderingContext -> Program -> Shader -> Effect Unit
foreign import linkProgram
    :: RenderingContext -> Program -> Effect Unit
foreign import useProgram
    :: RenderingContext -> Program -> Effect Unit
foreign import getProgramParameter
    :: RenderingContext -> Program -> Int -> Effect ProgramParameter
foreign import getProgramInfoLog
    :: RenderingContext -> Program -> Effect (Nullable String)
foreign import deleteProgram
    :: RenderingContext -> Program -> Effect Unit


type AttributeLocation = Int

foreign import getAttribLocation
    :: RenderingContext -> Program -> String -> Effect AttributeLocation


foreign import data UniformLocation :: Type

foreign import getUniformLocation
    :: RenderingContext -> Program -> String -> Effect (Nullable UniformLocation)
foreign import uniformMatrix4fv
    :: RenderingContext -> UniformLocation -> Boolean -> forall a. a -> Effect Unit
foreign import uniform4fv
    :: RenderingContext -> UniformLocation -> forall a. a -> Effect Unit


foreign import data VertexArrayObject :: Type

foreign import createVertexArray
    :: RenderingContext -> Effect (Nullable VertexArrayObject)
foreign import bindVertexArray
    :: RenderingContext -> VertexArrayObject -> Effect Unit


foreign import data Buffer :: Type

type BufferType = Int
arrayBuffer :: BufferType
arrayBuffer = 0x8892
elementArrayBuffer :: BufferType
elementArrayBuffer = 0x8893

foreign import createBuffer
    :: RenderingContext -> Effect (Nullable Buffer)
foreign import bindBuffer
    :: RenderingContext -> Int -> Buffer -> Effect Unit
foreign import bufferData
    :: RenderingContext -> Int -> forall a. a -> Int -> Effect Unit
foreign import vertexAttribPointer
    :: RenderingContext -> Int -> Int -> Int -> Boolean -> Int -> Int -> Effect Unit
foreign import enableVertexAttribArray
    :: RenderingContext -> Int -> Effect Unit


foreign import data XRSystem :: Type

foreign import getXRSystem :: forall a. a -> Effect (Nullable XRSystem)
foreign import makeXRCompatibleImpl :: RenderingContext -> Effect (Promise Unit)
makeXRCompatible :: RenderingContext -> Aff Unit
makeXRCompatible context = toAffE $ makeXRCompatibleImpl context

foreign import isWebXRSessionModeSupportedImpl :: XRSystem -> String -> Effect (Promise Boolean)
isWebXRSessionModeSupported :: XRSystem -> String -> Aff Boolean
isWebXRSessionModeSupported xrSystem mode = toAffE $ isWebXRSessionModeSupportedImpl xrSystem mode


type DrawUsage = Int
staticDraw :: DrawUsage
staticDraw = 0x88E4

float :: Int
float = 0x1406
