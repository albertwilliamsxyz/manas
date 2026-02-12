const webGL2Version = '#version 300 es'
const vertexShaderSource = webGL2Version + `
in vec4 a_position;

void main() {
  gl_Position = a_position;
}
`

const fragmentShaderSource = webGL2Version + `
precision highp float;

out vec4 outColor;

void main() {
  outColor = vec4(1.0, 1.0, 0.0, 1.0);
}
`

const main = async () => {
  /** @type {WebGL2RenderingContext} */
  const gl = application.getContext('webgl2');
  application.width = application.clientWidth
  application.height = application.clientHeight

  if (!gl) {
    console.error('WebGL2 not supported');
    return;
  }

  const vertexShader = gl.createShader(gl.VERTEX_SHADER)
  gl.shaderSource(vertexShader, vertexShaderSource)
  gl.compileShader(vertexShader)
  if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) {
    console.error('There was an error while compiling the vertexShader')
    console.error(gl.getShaderInfoLog(vertexShader))
    gl.deleteShader(vertexShader)
    return;
  }

  const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER)
  gl.shaderSource(fragmentShader, fragmentShaderSource)
  gl.compileShader(fragmentShader)
  if (!gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)) {
    console.error('There was an error while compiling the vertexShader')
    console.error(gl.getShaderInfoLog(fragmentShader))
    gl.deleteShader(fragmentShader)
    return;
  }

  const program = gl.createProgram()
  gl.attachShader(program, vertexShader)
  gl.attachShader(program, fragmentShader)
  gl.linkProgram(program)
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    console.error('Error while linking the program')
    console.error(gl.getProgramInfoLog(program))
    gl.deleteProgram(program)
    return
  }

  const positions = [
    0.1, 0.1,
    0.2, 0.5,
    0.75, 0.75,
  ]
  const positionBuffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer)
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW)

  const vertexArrayObject = gl.createVertexArray()
  gl.bindVertexArray(vertexArrayObject)

  const positionAttributeLocation = gl.getAttribLocation(program, 'a_position')
  gl.vertexAttribPointer(positionAttributeLocation, 2, gl.FLOAT, false, 0, 0)
  gl.enableVertexAttribArray(positionAttributeLocation)

  gl.useProgram(program)

  gl.viewport(0, 0, gl.canvas.width, gl.canvas.height)
  gl.clearColor(0, 0, 0, 1)
  gl.clear(gl.COLOR_BUFFER_BIT)

  gl.drawArrays(gl.TRIANGLES, 0, 3)

  gl.bindVertexArray(null)
}

await main()
