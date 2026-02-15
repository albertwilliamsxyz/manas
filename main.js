const cubeVertices = new Float32Array([
  -0.2, -0.2, 0.2,
  0.2, -0.2, 0.2,
  0.2, 0.2, 0.2,
  -0.2, -0.2, 0.2,
  0.2, 0.2, 0.2,
  -0.2, 0.2, 0.2,

  0.2, -0.2, -0.2,
  -0.2, -0.2, -0.2,
  -0.2, 0.2, -0.2,
  0.2, -0.2, -0.2,
  -0.2, 0.2, -0.2,
  0.2, 0.2, -0.2,

  0.2, -0.2, 0.2,
  0.2, -0.2, -0.2,
  0.2, 0.2, -0.2,
  0.2, -0.2, 0.2,
  0.2, 0.2, -0.2,
  0.2, 0.2, 0.2,

  -0.2, -0.2, -0.2,
  -0.2, -0.2, 0.2,
  -0.2, 0.2, 0.2,
  -0.2, -0.2, -0.2,
  -0.2, 0.2, 0.2,
  -0.2, 0.2, -0.2,

  -0.2, 0.2, 0.2,
  0.2, 0.2, 0.2,
  0.2, 0.2, -0.2,
  -0.2, 0.2, 0.2,
  0.2, 0.2, -0.2,
  -0.2, 0.2, -0.2,

  -0.2, -0.2, -0.2,
  0.2, -0.2, -0.2,
  0.2, -0.2, 0.2,
  -0.2, -0.2, -0.2,
  0.2, -0.2, 0.2,
  -0.2, -0.2, 0.2
]);

const webGL2Version = '#version 300 es'

const vertexShaderSource = webGL2Version + `
in vec3 a_position;
uniform mat4 u_projection;
uniform mat4 u_view;
void main() {
  gl_Position = u_projection * u_view * vec4(a_position, 1.0);
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
  await gl.makeXRCompatible();

  if (!gl) {
    alert('WebGL2 not supported');
    return;
  }

  const isWebXRSupported = await navigator.xr.isSessionSupported('immersive-vr');
  if (!isWebXRSupported) {
    alert('WebXR not supported');
    return;
  }

  const vertexShader = gl.createShader(gl.VERTEX_SHADER)
  gl.shaderSource(vertexShader, vertexShaderSource)
  gl.compileShader(vertexShader)
  if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) {
    alert('There was an error while compiling the vertexShader')
    alert(gl.getShaderInfoLog(vertexShader))
    gl.deleteShader(vertexShader)
    return;
  }

  const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER)
  gl.shaderSource(fragmentShader, fragmentShaderSource)
  gl.compileShader(fragmentShader)
  if (!gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)) {
    alert('There was an error while compiling the vertexShader')
    alert(gl.getShaderInfoLog(fragmentShader))
    gl.deleteShader(fragmentShader)
    return;
  }

  gl.enable(gl.DEPTH_TEST)

  const program = gl.createProgram()
  gl.attachShader(program, vertexShader)
  gl.attachShader(program, fragmentShader)
  gl.linkProgram(program)
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    alert('Error while linking the program')
    alert(gl.getProgramInfoLog(program))
    gl.deleteProgram(program)
    return
  }
  gl.useProgram(program)

  const numberOfDimensions = 3

  const positionBuffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer)
  gl.bufferData(gl.ARRAY_BUFFER, cubeVertices, gl.STATIC_DRAW)
  const numberOfVertices = cubeVertices.length / numberOfDimensions

  const vertexArrayObject = gl.createVertexArray()
  gl.bindVertexArray(vertexArrayObject)

  const positionAttributeLocation = gl.getAttribLocation(program, 'a_position')
  gl.vertexAttribPointer(
    positionAttributeLocation,
    numberOfDimensions,
    gl.FLOAT,
    false,
    0,
    0
  )
  gl.enableVertexAttribArray(positionAttributeLocation)

  const identityMatrix = new Float32Array([
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  ]);

  const projectionLocation = gl.getUniformLocation(program, 'u_projection');
  gl.uniformMatrix4fv(projectionLocation, false, identityMatrix);

  const viewLocation = gl.getUniformLocation(program, 'u_view');
  gl.uniformMatrix4fv(viewLocation, false, identityMatrix);

  startVRButton.onclick = async () => {
    const xrSession = await navigator.xr.requestSession('immersive-ar');

    if (!xrSession) {
      alert('Failed to start XR session');
      return;
    }

    const xrGLLayer = new XRWebGLLayer(xrSession, gl);
    xrSession.updateRenderState({
      baseLayer: xrGLLayer,
    });

    const referenceSpace = await xrSession.requestReferenceSpace('local');

    const onXRFrame = (time, xrFrame) => {
      const pose = xrFrame.getViewerPose(referenceSpace);
      if (!pose) {
        xrSession.requestAnimationFrame(onXRFrame);
        return;
      }

      gl.bindFramebuffer(gl.FRAMEBUFFER, xrGLLayer.framebuffer);

      gl.clearColor(0.0, 0.0, 0.0, 0.0);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

      for (const view of pose.views) {
        const viewport = xrGLLayer.getViewport(view);
        gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);
        gl.uniformMatrix4fv(projectionLocation, false, view.projectionMatrix);
        gl.uniformMatrix4fv(viewLocation, false, view.transform.inverse.matrix);

        gl.bindVertexArray(vertexArrayObject);
        gl.drawArrays(gl.TRIANGLES, 0, numberOfVertices);
      }

      xrSession.requestAnimationFrame(onXRFrame);
    }

    xrSession.requestAnimationFrame(onXRFrame)
  };
}

await main()
