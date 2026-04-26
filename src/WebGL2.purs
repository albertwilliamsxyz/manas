module WebGL2
  ( ShaderType(..)
  , makeShader
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
