module WebGL2 where

import Prelude

import Data.Nullable (Nullable)
import Effect (Effect)
import Web.HTML.HTMLCanvasElement (HTMLCanvasElement)

type ShaderType = Int

vertexShader :: ShaderType
vertexShader = 0x8B31

fragmentShader :: ShaderType 
fragmentShader = 0x8B30

type BufferType = Int

arrayBuffer :: BufferType
arrayBuffer = 0x8892

elementArrayBuffer :: BufferType
elementArrayBuffer = 0x8893

compileStatus :: Int
compileStatus = 0x8B81

linkStatus :: Int
linkStatus = 0x8B82

type ShaderParameter = Boolean

type ProgramParameter = Boolean

foreign import data RenderingContext :: Type

foreign import data Shader :: Type

foreign import data Program :: Type

foreign import createContext
    :: HTMLCanvasElement -> Effect (Nullable RenderingContext)

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
