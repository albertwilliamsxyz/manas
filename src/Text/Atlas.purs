module Text.Atlas
  ( Atlas
  , GlyphMetrics
  , loadAtlas
  ) where

import Prelude

import Control.Monad.Except (ExceptT)
import Control.Promise (Promise, toAffE)
import Data.Array as Array
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.String.CodeUnits (charAt)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Aff.Class (class MonadAff, liftAff)
import Image (loadImage)
import WebGL2 (TextureFilter(..), TextureWrap(..), makeTextureFromImage)
import WebGL2.Raw as Raw


type GlyphMetrics =
    { x :: Number
    , y :: Number
    , width :: Number
    , height :: Number
    , xoffset :: Number
    , yoffset :: Number
    , xadvance :: Number
    }


type GlyphInJson =
    { char :: String
    , x :: Number
    , y :: Number
    , width :: Number
    , height :: Number
    , xoffset :: Number
    , yoffset :: Number
    , xadvance :: Number
    }


type AtlasMetadata =
    { scaleW :: Number
    , scaleH :: Number
    , lineHeight :: Number
    , distanceRange :: Number
    , glyphs :: Array GlyphInJson
    }


type Atlas =
    { texture :: Raw.Texture
    , glyphs :: Map Char GlyphMetrics
    , scaleW :: Number
    , scaleH :: Number
    , lineHeight :: Number
    , distanceRange :: Number
    }


foreign import loadAtlasMetadataImpl :: String -> Effect (Promise AtlasMetadata)


loadAtlasMetadata :: String -> Aff AtlasMetadata
loadAtlasMetadata = toAffE <<< loadAtlasMetadataImpl


loadAtlas
  :: forall m. MonadAff m
  => Raw.RenderingContext
  -> { png :: String, json :: String }
  -> ExceptT String m Atlas
loadAtlas gl paths = do
  metadata <- liftAff $ loadAtlasMetadata paths.json
  imageElement <- liftAff $ loadImage paths.png
  texture <- makeTextureFromImage gl imageElement
              { minification: Linear, magnification: Linear }
              { horizontal: ClampToEdge, vertical: ClampToEdge }
  pure
    { texture
    , glyphs: Map.fromFoldable $ Array.mapMaybe toGlyphEntry metadata.glyphs
    , scaleW: metadata.scaleW
    , scaleH: metadata.scaleH
    , lineHeight: metadata.lineHeight
    , distanceRange: metadata.distanceRange
    }
  where
  toGlyphEntry :: GlyphInJson -> Maybe (Tuple Char GlyphMetrics)
  toGlyphEntry g = case charAt 0 g.char of
    Just c -> Just $ Tuple c
                { x: g.x
                , y: g.y
                , width: g.width
                , height: g.height
                , xoffset: g.xoffset
                , yoffset: g.yoffset
                , xadvance: g.xadvance
                }
    Nothing -> Nothing
