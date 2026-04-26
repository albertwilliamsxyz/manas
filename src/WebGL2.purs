module WebGL2
  ( ShaderType(..)
  , makeShader
  , makeProgram
  , makeBuffer
  , makeVertexArrayObject
  ) where

import Prelude

import Control.Monad.Except (ExceptT, except)
import Data.Either (Either(..), note)
import Data.Maybe (fromMaybe)
import Data.Nullable (toMaybe)
import Effect.Class (class MonadEffect, liftEffect)
import Unsafe.Coerce (unsafeCoerce)
import WebGL2.Raw as Raw


data ShaderType = VertexShader | FragmentShader

toRawShaderType :: ShaderType -> Int
toRawShaderType VertexShader = Raw.vertexShader
toRawShaderType FragmentShader = Raw.fragmentShader


makeShader
  :: forall m. MonadEffect m
  => Raw.RenderingContext
  -> ShaderType
  -> String
  -> ExceptT String m Raw.Shader
makeShader gl shaderType source = do
  nullableShader <- liftEffect $ Raw.createShader gl (toRawShaderType shaderType)
  shader <- except $ note "Shader could not be created" (toMaybe nullableShader)
  liftEffect $ Raw.shaderSource gl shader source
  liftEffect $ Raw.compileShader gl shader
  status <- liftEffect $ Raw.getShaderParameter gl shader Raw.compileStatus
  if unsafeCoerce status :: Boolean
    then pure shader
    else do
      nullableLog <- liftEffect $ Raw.getShaderInfoLog gl shader
      liftEffect $ Raw.deleteShader gl shader
      except $ Left $ fromMaybe "Unknown shader compile error" (toMaybe nullableLog)


makeProgram
  :: forall m. MonadEffect m
  => Raw.RenderingContext
  -> { vertex :: Raw.Shader, fragment :: Raw.Shader }
  -> ExceptT String m Raw.Program
makeProgram gl shaders = do
  nullableProgram <- liftEffect $ Raw.createProgram gl
  program <- except $ note "Program could not be created" (toMaybe nullableProgram)
  liftEffect $ Raw.attachShader gl program shaders.vertex
  liftEffect $ Raw.attachShader gl program shaders.fragment
  liftEffect $ Raw.linkProgram gl program
  status <- liftEffect $ Raw.getProgramParameter gl program Raw.linkStatus
  if unsafeCoerce status :: Boolean
    then pure program
    else do
      nullableLog <- liftEffect $ Raw.getProgramInfoLog gl program
      liftEffect $ Raw.deleteShader gl shaders.vertex
      liftEffect $ Raw.deleteShader gl shaders.fragment
      liftEffect $ Raw.deleteProgram gl program
      except $ Left $ fromMaybe "Unknown program link error" (toMaybe nullableLog)


makeBuffer
  :: forall m. MonadEffect m
  => Raw.RenderingContext
  -> String
  -> ExceptT String m Raw.Buffer
makeBuffer gl description = do
  nullableBuffer <- liftEffect $ Raw.createBuffer gl
  except $ note (description <> " could not be created") (toMaybe nullableBuffer)


makeVertexArrayObject
  :: forall m. MonadEffect m
  => Raw.RenderingContext
  -> String
  -> ExceptT String m Raw.VertexArrayObject
makeVertexArrayObject gl description = do
  nullableVAO <- liftEffect $ Raw.createVertexArray gl
  except $ note (description <> " could not be created") (toMaybe nullableVAO)
