module Text.Layout
  ( TextGeometryData
  , layoutText
  ) where

import Prelude

import Data.Array (length)
import Data.Foldable (foldl)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.String.CodeUnits (toCharArray)
import Math.Vec3 (Vec3)
import Math.Vec3 as Math.Vec3
import Text.Atlas (Atlas, GlyphMetrics)


type TextGeometryData =
    { vertices :: Array Vec3
    , uvs :: Array Number
    , triangleIndices :: Array Int
    }


type LayoutState =
    { cursor :: Number
    , vertices :: Array Vec3
    , uvs :: Array Number
    , triangleIndices :: Array Int
    }


layoutText :: Atlas -> { content :: String, scale :: Number } -> TextGeometryData
layoutText atlas { content, scale } =
    let final = foldl step initialState (toCharArray content)
    in { vertices: final.vertices
       , uvs: final.uvs
       , triangleIndices: final.triangleIndices
       }
  where
  initialState :: LayoutState
  initialState = { cursor: 0.0, vertices: [], uvs: [], triangleIndices: [] }

  spaceAdvance :: Number
  spaceAdvance = case Map.lookup 'x' atlas.glyphs of
    Just g -> g.xadvance
    Nothing -> 16.0

  step :: LayoutState -> Char -> LayoutState
  step state c = case Map.lookup c atlas.glyphs of
    Just g -> emitGlyph state g
    Nothing | c == ' ' -> state { cursor = state.cursor + spaceAdvance }
    Nothing -> state

  emitGlyph :: LayoutState -> GlyphMetrics -> LayoutState
  emitGlyph state g =
    let baseIndex = length state.vertices
        localLeft = state.cursor + g.xoffset
        localRight = localLeft + g.width
        localTop = g.yoffset
        localBottom = localTop + g.height
        xLeft = localLeft * scale
        xRight = localRight * scale
        yTop = -localTop * scale
        yBottom = -localBottom * scale
        uLeft = g.x / atlas.scaleW
        uRight = (g.x + g.width) / atlas.scaleW
        vTop = g.y / atlas.scaleH
        vBottom = (g.y + g.height) / atlas.scaleH
    in { cursor: state.cursor + g.xadvance
       , vertices: state.vertices <>
           [ Math.Vec3.vec3 xLeft  yBottom 0.0
           , Math.Vec3.vec3 xRight yBottom 0.0
           , Math.Vec3.vec3 xRight yTop    0.0
           , Math.Vec3.vec3 xLeft  yTop    0.0
           ]
       , uvs: state.uvs <>
           [ uLeft,  vBottom
           , uRight, vBottom
           , uRight, vTop
           , uLeft,  vTop
           ]
       , triangleIndices: state.triangleIndices <>
           [ baseIndex, baseIndex + 1, baseIndex + 2
           , baseIndex, baseIndex + 2, baseIndex + 3
           ]
       }
