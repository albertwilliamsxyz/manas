module Manas.Shaders where

import Prelude

webgl2VersionDeclaration :: String
webgl2VersionDeclaration = "#version 300 es"

vertexShaderSource :: String
vertexShaderSource = webgl2VersionDeclaration <> """
in vec3 a_position;
uniform mat4 u_projection;
uniform mat4 u_view;
uniform mat4 u_model;
void main() {
  gl_Position = u_projection * u_view * u_model * vec4(a_position, 1.0);
  gl_PointSize = 10.0;
}
"""

fragmentShaderSource :: String
fragmentShaderSource = webgl2VersionDeclaration <> """
precision highp float;
out vec4 outColor;
uniform vec4 u_color;
void main() {
  outColor = u_color;
}
"""
