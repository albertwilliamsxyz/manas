module Main where

import Prelude

import Control.Monad.Except (except, runExceptT)
import Data.Either (Either(..), note)
import Data.Maybe (fromMaybe)
import Data.Nullable (toMaybe)
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Web.DOM.NonElementParentNode (getElementById)
import Web.HTML (window)
import Web.HTML.HTMLCanvasElement as HTMLCanvasElement
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.Window (document)
import WebGL2 as WebGL2

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
main = do
    win <- window
    doc <- document win
    result <- runExceptT do
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
        if not programCompiledSuccessfully
            then do
                nullableErrorMessage <- liftEffect $ WebGL2.getProgramInfoLog webGL2Context program
                liftEffect $ WebGL2.deleteShader webGL2Context vertexShader
                liftEffect $ WebGL2.deleteShader webGL2Context fragmentShader
                liftEffect $ WebGL2.deleteProgram webGL2Context program
                except $ Left $ fromMaybe "Unknown Error when linking program" (toMaybe nullableErrorMessage)
            else do
                liftEffect $ WebGL2.useProgram webGL2Context program
                except $ Right "Program created successfully"
    case result of
        Left errorMessage -> log errorMessage
        Right message -> log message
