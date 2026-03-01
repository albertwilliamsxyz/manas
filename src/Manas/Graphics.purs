module Manas.Graphics
  ( WebGL2Context
  , WebGLShader
  , WebGLProgram
  , WebGLBuffer
  , WebGLVertexArray
  , WebGLUniformLocation
  , WebGLFramebuffer
  , getWebGL2Context
  , createShader
  , shaderSource
  , compileShader
  , getShaderParameter
  , getShaderInfoLog
  , deleteShader
  , createProgram
  , attachShader
  , linkProgram
  , getProgramParameter
  , getProgramInfoLog
  , deleteProgram
  , useProgram
  , getAttribLocation
  , getUniformLocation
  , enableDepthTest
  , createVertexArray
  , bindVertexArray
  , createBuffer
  , bindArrayBuffer
  , bindElementArrayBuffer
  , bufferDataStaticDraw
  , bufferDataDynamicDraw
  , bufferDataElementStaticDraw
  , bufferSubData
  , vertexAttribPointer
  , enableVertexAttribArray
  , uniformMatrix4fv
  , uniform4fv
  , clearColor
  , clear
  , viewport
  , drawArraysPoints
  , drawArraysLineLoop
  , drawElementsLines
  , bindFramebuffer
  , makeXRCompatible
  , vertexShaderType
  , fragmentShaderType
  ) where

import Prelude
import Effect (Effect)
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toMaybe)

foreign import data WebGL2Context :: Type
foreign import data WebGLShader :: Type
foreign import data WebGLProgram :: Type
foreign import data WebGLBuffer :: Type
foreign import data WebGLVertexArray :: Type
foreign import data WebGLUniformLocation :: Type
foreign import data WebGLFramebuffer :: Type

foreign import vertexShaderType :: Int
foreign import fragmentShaderType :: Int

foreign import getWebGL2ContextImpl :: String -> Effect (Nullable WebGL2Context)

getWebGL2Context :: String -> Effect (Maybe WebGL2Context)
getWebGL2Context canvasId = map toMaybe (getWebGL2ContextImpl canvasId)

foreign import createShaderImpl :: WebGL2Context -> Int -> Effect (Nullable WebGLShader)

createShader :: WebGL2Context -> Int -> Effect (Maybe WebGLShader)
createShader gl shaderType = map toMaybe (createShaderImpl gl shaderType)

foreign import shaderSource :: WebGL2Context -> WebGLShader -> String -> Effect Unit
foreign import compileShader :: WebGL2Context -> WebGLShader -> Effect Unit
foreign import getShaderParameter :: WebGL2Context -> WebGLShader -> Effect Boolean
foreign import getShaderInfoLog :: WebGL2Context -> WebGLShader -> Effect String
foreign import deleteShader :: WebGL2Context -> WebGLShader -> Effect Unit

foreign import createProgramImpl :: WebGL2Context -> Effect (Nullable WebGLProgram)

createProgram :: WebGL2Context -> Effect (Maybe WebGLProgram)
createProgram gl = map toMaybe (createProgramImpl gl)

foreign import attachShader :: WebGL2Context -> WebGLProgram -> WebGLShader -> Effect Unit
foreign import linkProgram :: WebGL2Context -> WebGLProgram -> Effect Unit
foreign import getProgramParameter :: WebGL2Context -> WebGLProgram -> Effect Boolean
foreign import getProgramInfoLog :: WebGL2Context -> WebGLProgram -> Effect String
foreign import deleteProgram :: WebGL2Context -> WebGLProgram -> Effect Unit
foreign import useProgram :: WebGL2Context -> WebGLProgram -> Effect Unit

foreign import getAttribLocation :: WebGL2Context -> WebGLProgram -> String -> Effect Int

foreign import getUniformLocationImpl :: WebGL2Context -> WebGLProgram -> String -> Effect (Nullable WebGLUniformLocation)

getUniformLocation :: WebGL2Context -> WebGLProgram -> String -> Effect (Maybe WebGLUniformLocation)
getUniformLocation gl prog name = map toMaybe (getUniformLocationImpl gl prog name)

foreign import enableDepthTest :: WebGL2Context -> Effect Unit

foreign import createVertexArray :: WebGL2Context -> Effect WebGLVertexArray
foreign import bindVertexArray :: WebGL2Context -> WebGLVertexArray -> Effect Unit

foreign import createBuffer :: WebGL2Context -> Effect WebGLBuffer
foreign import bindArrayBuffer :: WebGL2Context -> WebGLBuffer -> Effect Unit
foreign import bindElementArrayBuffer :: WebGL2Context -> WebGLBuffer -> Effect Unit

foreign import bufferDataStaticDraw :: WebGL2Context -> Array Number -> Effect Unit
foreign import bufferDataDynamicDraw :: WebGL2Context -> Int -> Effect Unit
foreign import bufferDataElementStaticDraw :: WebGL2Context -> Array Int -> Effect Unit
foreign import bufferSubData :: WebGL2Context -> Array Number -> Effect Unit

foreign import vertexAttribPointer :: WebGL2Context -> Int -> Int -> Effect Unit
foreign import enableVertexAttribArray :: WebGL2Context -> Int -> Effect Unit

foreign import uniformMatrix4fv :: WebGL2Context -> WebGLUniformLocation -> Array Number -> Effect Unit
foreign import uniform4fv :: WebGL2Context -> WebGLUniformLocation -> Array Number -> Effect Unit

foreign import clearColor :: WebGL2Context -> Number -> Number -> Number -> Number -> Effect Unit
foreign import clear :: WebGL2Context -> Effect Unit
foreign import viewport :: WebGL2Context -> Int -> Int -> Int -> Int -> Effect Unit

foreign import drawArraysPoints :: WebGL2Context -> Int -> Int -> Effect Unit
foreign import drawArraysLineLoop :: WebGL2Context -> Int -> Int -> Effect Unit
foreign import drawElementsLines :: WebGL2Context -> Int -> Effect Unit

foreign import bindFramebuffer :: WebGL2Context -> WebGLFramebuffer -> Effect Unit

foreign import makeXRCompatible :: WebGL2Context -> Effect Unit
