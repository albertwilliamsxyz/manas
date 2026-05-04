module WebGL2
  ( ShaderType(..)
  , TextureFilter(..)
  , TextureWrap(..)
  , makeShader
  , makeProgram
  , makeBuffer
  , makeVertexArrayObject
  , makeTexture
  , makeTextureFromImage
  , makeFramebuffer
  , findUniformLocation
  ) where

import Prelude

import Control.Monad.Except (ExceptT, except)
import Data.Either (Either(..), note)
import Data.Maybe (fromMaybe)
import Data.Nullable (notNull, null, toMaybe)
import Effect.Class (class MonadEffect, liftEffect)
import Primitives as Primitives
import Unsafe.Coerce (unsafeCoerce)
import Web.HTML.HTMLImageElement (HTMLImageElement)
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
  -> ExceptT String m Raw.Buffer
makeBuffer gl = do
  nullableBuffer <- liftEffect $ Raw.createBuffer gl
  except $ note "Buffer could not be created" (toMaybe nullableBuffer)


makeVertexArrayObject
  :: forall m. MonadEffect m
  => Raw.RenderingContext
  -> ExceptT String m Raw.VertexArrayObject
makeVertexArrayObject gl = do
  nullableVertexArrayObject <- liftEffect $ Raw.createVertexArray gl
  except $ note "Vertex array object could not be created" (toMaybe nullableVertexArrayObject)


findUniformLocation
  :: forall m. MonadEffect m
  => Raw.RenderingContext
  -> Raw.Program
  -> String
  -> ExceptT String m Raw.UniformLocation
findUniformLocation gl program name = do
  nullableLocation <- liftEffect $ Raw.getUniformLocation gl program name
  except $ note ("Uniform location not found: " <> name) (toMaybe nullableLocation)


data TextureFilter = Nearest | Linear

toRawFilter :: TextureFilter -> Int
toRawFilter Nearest = Raw.nearest
toRawFilter Linear = Raw.linear


data TextureWrap = Repeat | ClampToEdge

toRawWrap :: TextureWrap -> Int
toRawWrap Repeat = Raw.repeat
toRawWrap ClampToEdge = Raw.clampToEdge


makeTexture
  :: forall m. MonadEffect m
  => Raw.RenderingContext
  -> { width :: Int, height :: Int }
  -> { minification :: TextureFilter, magnification :: TextureFilter }
  -> { horizontal :: TextureWrap, vertical :: TextureWrap }
  -> Primitives.Uint8Array
  -> ExceptT String m Raw.Texture
makeTexture gl { width, height } filter wrap pixels = do
  nullableTexture <- liftEffect $ Raw.createTexture gl
  texture <- except $ note "Texture could not be created" (toMaybe nullableTexture)
  liftEffect do
    Raw.bindTexture gl Raw.texture2D (notNull texture)
    Raw.texImage2D gl Raw.texture2D 0 Raw.rgba8 width height 0 Raw.rgba Raw.unsignedByte
                   (Primitives.u8AsArrayBufferView pixels)
    Raw.texParameteri gl Raw.texture2D Raw.textureMinFilter (toRawFilter filter.minification)
    Raw.texParameteri gl Raw.texture2D Raw.textureMagFilter (toRawFilter filter.magnification)
    Raw.texParameteri gl Raw.texture2D Raw.textureWrapS (toRawWrap wrap.horizontal)
    Raw.texParameteri gl Raw.texture2D Raw.textureWrapT (toRawWrap wrap.vertical)
  pure texture


makeTextureFromImage
  :: forall m. MonadEffect m
  => Raw.RenderingContext
  -> HTMLImageElement
  -> { minification :: TextureFilter, magnification :: TextureFilter }
  -> { horizontal :: TextureWrap, vertical :: TextureWrap }
  -> ExceptT String m Raw.Texture
makeTextureFromImage gl image filter wrap = do
  nullableTexture <- liftEffect $ Raw.createTexture gl
  texture <- except $ note "Texture could not be created" (toMaybe nullableTexture)
  liftEffect do
    Raw.bindTexture gl Raw.texture2D (notNull texture)
    Raw.texImage2DFromImage gl Raw.texture2D 0 Raw.rgba Raw.rgba Raw.unsignedByte image
    Raw.texParameteri gl Raw.texture2D Raw.textureMinFilter (toRawFilter filter.minification)
    Raw.texParameteri gl Raw.texture2D Raw.textureMagFilter (toRawFilter filter.magnification)
    Raw.texParameteri gl Raw.texture2D Raw.textureWrapS (toRawWrap wrap.horizontal)
    Raw.texParameteri gl Raw.texture2D Raw.textureWrapT (toRawWrap wrap.vertical)
  pure texture


makeFramebuffer
  :: forall m. MonadEffect m
  => Raw.RenderingContext
  -> Raw.Texture
  -> ExceptT String m Raw.Framebuffer
makeFramebuffer gl texture = do
  nullableFramebuffer <- liftEffect $ Raw.createFramebuffer gl
  framebuffer <- except $ note "Framebuffer could not be created" (toMaybe nullableFramebuffer)
  liftEffect do
    Raw.bindFramebuffer gl Raw.framebuffer (notNull framebuffer)
    Raw.framebufferTexture2D gl Raw.framebuffer Raw.colorAttachment0 Raw.texture2D (notNull texture) 0
  status <- liftEffect $ Raw.checkFramebufferStatus gl Raw.framebuffer
  liftEffect $ Raw.bindFramebuffer gl Raw.framebuffer null
  if status == Raw.framebufferComplete
    then pure framebuffer
    else except $ Left ("Framebuffer incomplete: " <> show status)
