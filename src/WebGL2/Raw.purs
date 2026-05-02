module WebGL2.Raw where

import Prelude

import Data.Nullable (Nullable)
import Effect (Effect)
import Primitives (ArrayBufferView, Float32Array)
import Web.HTML.HTMLCanvasElement (HTMLCanvasElement)


foreign import data RenderingContext :: Type
foreign import getContext
    :: HTMLCanvasElement -> Effect (Nullable RenderingContext)

vertexShader :: Int
vertexShader = 0x8B31
fragmentShader :: Int
fragmentShader = 0x8B30

compileStatus :: Int
compileStatus = 0x8B81
linkStatus :: Int
linkStatus = 0x8B82


foreign import data Shader :: Type
foreign import data ShaderParameter :: Type

foreign import createShader
    :: RenderingContext -> Int -> Effect (Nullable Shader)
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
foreign import data ProgramParameter :: Type

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


foreign import getAttribLocation
    :: RenderingContext -> Program -> String -> Effect Int


foreign import data UniformLocation :: Type

foreign import getUniformLocation
    :: RenderingContext -> Program -> String -> Effect (Nullable UniformLocation)
foreign import uniformMatrix4fv
    :: RenderingContext -> UniformLocation -> Boolean -> Float32Array -> Effect Unit
foreign import uniform4fv
    :: RenderingContext -> UniformLocation -> Float32Array -> Effect Unit
foreign import uniform1i
    :: RenderingContext -> UniformLocation -> Int -> Effect Unit


foreign import data VertexArrayObject :: Type

foreign import createVertexArray
    :: RenderingContext -> Effect (Nullable VertexArrayObject)
foreign import bindVertexArray
    :: RenderingContext -> Nullable VertexArrayObject -> Effect Unit


foreign import data Buffer :: Type

arrayBuffer :: Int
arrayBuffer = 0x8892
elementArrayBuffer :: Int
elementArrayBuffer = 0x8893

foreign import createBuffer
    :: RenderingContext -> Effect (Nullable Buffer)
foreign import bindBuffer
    :: RenderingContext -> Int -> Nullable Buffer -> Effect Unit
foreign import bufferData
    :: RenderingContext -> Int -> ArrayBufferView -> Int -> Effect Unit
foreign import bufferSubData
    :: RenderingContext -> Int -> Int -> ArrayBufferView -> Effect Unit
foreign import vertexAttribPointer
    :: RenderingContext -> Int -> Int -> Int -> Boolean -> Int -> Int -> Effect Unit
foreign import enableVertexAttribArray
    :: RenderingContext -> Int -> Effect Unit


staticDraw :: Int
staticDraw = 0x88E4
dynamicDraw :: Int
dynamicDraw = 0x88E8

float :: Int
float = 0x1406

depthTest :: Int
depthTest = 0x0B71

foreign import enable :: RenderingContext -> Int -> Effect Unit

foreign import data Texture :: Type

texture2D :: Int
texture2D = 0x0DE1
texture0 :: Int
texture0 = 0x84C0

textureMagFilter :: Int
textureMagFilter = 0x2800
textureMinFilter :: Int
textureMinFilter = 0x2801
textureWrapS :: Int
textureWrapS = 0x2802
textureWrapT :: Int
textureWrapT = 0x2803

nearest :: Int
nearest = 0x2600
linear :: Int
linear = 0x2601
linearMipmapLinear :: Int
linearMipmapLinear = 0x2703

repeat :: Int
repeat = 0x2901
clampToEdge :: Int
clampToEdge = 0x812F

rgba :: Int
rgba = 0x1908
rgba8 :: Int
rgba8 = 0x8058
unsignedByte :: Int
unsignedByte = 0x1401

foreign import createTexture
    :: RenderingContext -> Effect (Nullable Texture)
foreign import bindTexture
    :: RenderingContext -> Int -> Nullable Texture -> Effect Unit
foreign import texImage2D
    :: RenderingContext -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> ArrayBufferView -> Effect Unit
foreign import texParameteri
    :: RenderingContext -> Int -> Int -> Int -> Effect Unit
foreign import generateMipmap
    :: RenderingContext -> Int -> Effect Unit
foreign import activeTexture
    :: RenderingContext -> Int -> Effect Unit

foreign import data Framebuffer :: Type

foreign import bindFramebuffer :: RenderingContext -> Int -> Nullable Framebuffer -> Effect Unit

foreign import clearColor :: RenderingContext -> Number -> Number -> Number -> Number -> Effect Unit
foreign import clear :: RenderingContext -> Int -> Effect Unit

foreign import viewport :: RenderingContext -> Int -> Int -> Int -> Int -> Effect Unit

foreign import drawArrays :: RenderingContext -> Int -> Int -> Int -> Effect Unit
foreign import drawElements :: RenderingContext -> Int -> Int -> Int -> Int -> Effect Unit

framebuffer :: Int
framebuffer = 0x8D40

colorBufferBit :: Int
colorBufferBit = 0x00004000

depthBufferBit :: Int
depthBufferBit = 0x00000100

points :: Int
points = 0x0000

lines :: Int
lines = 0x0001

triangles :: Int
triangles = 0x0004

unsignedShort :: Int
unsignedShort = 0x1403
