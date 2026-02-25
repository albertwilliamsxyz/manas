import * as O from 'fp-ts/Option'
import * as E from 'fp-ts/Either'
import { pipe } from 'fp-ts/function'

const IDENTITY_MATRIX: Float32Array = new Float32Array([
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1
])

const BASE_NUMBER_OF_DIMENSIONS: number = 3

const NUMBER_OF_JOINTS_PER_HAND: number = 25
const NUMBER_OF_HAND_JOINT_DIMENSIONS: number = NUMBER_OF_JOINTS_PER_HAND * BASE_NUMBER_OF_DIMENSIONS

const HAND_SKELETON_BY_JOINT_INDICES: number[] = [
  0, 1, 1, 2, 2, 3, 3, 4,
  0, 5, 5, 6, 6, 7, 7, 8, 8, 9,
  0, 10, 10, 11, 11, 12, 12, 13, 13, 14,
  0, 15, 15, 16, 16, 17, 17, 18, 18, 19,
  0, 20, 20, 21, 21, 22, 22, 23, 23, 24
]

const HAND_JOINT_INDICES_BY_NAME: { [key: string]: number } = {
  'wrist': 0,

  'thumb-metacarpal': 1,
  'thumb-phalanx-proximal': 2,
  'thumb-phalanx-distal': 3,
  'thumb-tip': 4,

  'index-finger-metacarpal': 5,
  'index-finger-phalanx-proximal': 6,
  'index-finger-phalanx-intermediate': 7,
  'index-finger-phalanx-distal': 8,
  'index-finger-tip': 9,

  'middle-finger-metacarpal': 10,
  'middle-finger-phalanx-proximal': 11,
  'middle-finger-phalanx-intermediate': 12,
  'middle-finger-phalanx-distal': 13,
  'middle-finger-tip': 14,

  'ring-finger-metacarpal': 15,
  'ring-finger-phalanx-proximal': 16,
  'ring-finger-phalanx-intermediate': 17,
  'ring-finger-phalanx-distal': 18,
  'ring-finger-tip': 19,

  'pinky-finger-metacarpal': 20,
  'pinky-finger-phalanx-proximal': 21,
  'pinky-finger-phalanx-intermediate': 22,
  'pinky-finger-phalanx-distal': 23,
  'pinky-finger-tip': 24
}

const WEBGL_2_VERSION_DECLARATION: string = '#version 300 es'

const VERTEX_SHADER_SOURCE: string = WEBGL_2_VERSION_DECLARATION + `
in vec3 a_position;
uniform mat4 u_projection;
uniform mat4 u_view;
uniform mat4 u_model;
void main() {
  gl_Position = u_projection * u_view * u_model * vec4(a_position, 1.0);
  gl_PointSize = 10.0;
}
`

const FRAGMENT_SHADER_SOURCE: string = WEBGL_2_VERSION_DECLARATION + `
precision highp float;
out vec4 outColor;
uniform vec4 u_color;
void main() {
  outColor = u_color;
}
`

// 0. Navigator Layer

const getApplicationCanvas = (): O.Option<HTMLCanvasElement> => {
  const applicationCanvas: HTMLCanvasElement | null = (
    document.getElementById('application') as HTMLCanvasElement | null
  )
  return applicationCanvas ? O.some(applicationCanvas) : O.none
}

// 1. Core Layer (when defined)

// 2. Graphics Layer

const createGraphicLibraryContext: (applicationCanvas: HTMLCanvasElement) => E.Either<Error, WebGL2RenderingContext> = (
  applicationCanvas: HTMLCanvasElement
) => {
  const gl: WebGL2RenderingContext | null = applicationCanvas.getContext('webgl2')
  return gl ? E.right(gl) : E.left(new Error('WebGL2 not supported'))
}

const createVertexShader: (gl: WebGL2RenderingContext) => E.Either<Error, WebGLShader> = (
  gl: WebGL2RenderingContext
) => {
  const vertexShader: WebGLShader | null = gl.createShader(gl.VERTEX_SHADER)
  return vertexShader ? E.right(vertexShader) : E.left(new Error('Unable to create vertex shader'))
}

const initializeVertexShader: (
  gl: WebGL2RenderingContext,
  vertexShader: WebGLShader
) => E.Either<Error, WebGLShader> = (
  gl: WebGL2RenderingContext,
  vertexShader: WebGLShader
) => {
    gl.shaderSource(vertexShader, VERTEX_SHADER_SOURCE)
    gl.compileShader(vertexShader)
    const compiledSuccessfully: boolean = Boolean(gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS))
    if (compiledSuccessfully) {
      return E.right(vertexShader)
    } else {
      gl.deleteShader(vertexShader)
      const errorMessage: string = gl.getShaderInfoLog(vertexShader) || 'Unknown error'
      return E.left(
        new Error(
          `There was an error while compiling the ${gl.VERTEX_SHADER} shader: ${errorMessage}`
        )
      )
    }
  }

const createFragmentShader: (gl: WebGL2RenderingContext) => E.Either<Error, WebGLShader> = (
  gl: WebGL2RenderingContext
) => {
  const fragmentShader: WebGLShader | null = gl.createShader(gl.FRAGMENT_SHADER)
  return fragmentShader ? E.right(fragmentShader) : E.left(new Error('Unable to create fragment shader'))
}

const initializeFragmentShader: (
  gl: WebGL2RenderingContext,
  fragmentShader: WebGLShader
) => E.Either<Error, WebGLShader> = (
  gl: WebGL2RenderingContext,
  fragmentShader: WebGLShader
) => {
    gl.shaderSource(fragmentShader, FRAGMENT_SHADER_SOURCE)
    gl.compileShader(fragmentShader)
    const compiledSuccessfully: boolean = Boolean(gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS))
    if (compiledSuccessfully) {
      return E.right(fragmentShader)
    } else {
      gl.deleteShader(fragmentShader)
      const errorMessage: string = gl.getShaderInfoLog(fragmentShader) || 'Unknown error'
      return E.left(
        new Error(
          `There was an error while compiling the ${gl.FRAGMENT_SHADER} shader: ${errorMessage}`
        )
      )
    }
  }

const createProgram = (gl: WebGL2RenderingContext): WebGLProgram => {
  return gl.createProgram()
}

const initializeProgram = (
  gl: WebGL2RenderingContext,
  program: WebGLProgram,
  vertexShader: WebGLShader,
  fragmentShader: WebGLShader
): E.Either<Error, WebGLProgram> => {
  for (const shader of [vertexShader, fragmentShader]) {
    gl.attachShader(program, shader)
  }
  gl.linkProgram(program)
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    gl.deleteProgram(program)
    const errorMessage: string = gl.getProgramInfoLog(program) || 'Unknown error'
    return E.left(new Error(`Error while linking the program: ${errorMessage}`))
  }
  gl.useProgram(program)
  return E.right(program)
}

console.log('Starting application');

(async () => {
  const applicationCanvas: HTMLCanvasElement | null = pipe(
    getApplicationCanvas(),
    O.match(
      () => { throw new Error('Application canvas not found') },
      (canvas: HTMLCanvasElement) => canvas
    )
  )

  const gl: WebGL2RenderingContext | null = E.match(
    (error: Error) => { throw error },
    (gl: WebGL2RenderingContext) => gl
  )(createGraphicLibraryContext(applicationCanvas))

  const vertexShader: WebGLShader = pipe(
    createVertexShader(gl),
    E.chain((vertexShader: WebGLShader) => initializeVertexShader(gl, vertexShader)),
    E.match(
      (error: Error) => { throw error },
      (vertexShader: WebGLShader) => vertexShader
    )
  )

  const fragmentShader: WebGLShader = pipe(
    createFragmentShader(gl),
    E.chain((fragmentShader: WebGLShader) => initializeFragmentShader(gl, fragmentShader)),
    E.match(
      (error: Error) => { throw error },
      (fragmentShader: WebGLShader) => fragmentShader
    )
  )

  gl.enable(gl.DEPTH_TEST)

  const program: WebGLProgram = pipe(
    createProgram(gl),
    (program: WebGLProgram) => initializeProgram(gl, program, vertexShader, fragmentShader),
    E.match(
      (error: Error) => { throw error },
      (program: WebGLProgram) => program
    )
  )

  const positionLocation: GLint = gl.getAttribLocation(program, 'a_position')

  const projectionLocation: WebGLUniformLocation | null = gl.getUniformLocation(program, 'u_projection')
  if (!projectionLocation) {
    console.error('Unable to get the location of the projection uniform')
    return
  }
  gl.uniformMatrix4fv(projectionLocation, false, IDENTITY_MATRIX)

  const viewLocation: WebGLUniformLocation | null = gl.getUniformLocation(program, 'u_view')
  if (!viewLocation) {
    console.error('Unable to get the location of the view uniform')
    return
  }
  gl.uniformMatrix4fv(viewLocation, false, IDENTITY_MATRIX)

  const modelLocation: WebGLUniformLocation | null = gl.getUniformLocation(program, 'u_model')
  if (!modelLocation) {
    console.error('Unable to get the location of the model uniform')
    return
  }
  gl.uniformMatrix4fv(modelLocation, false, IDENTITY_MATRIX)

  const colorLocation: WebGLUniformLocation | null = gl.getUniformLocation(program, 'u_color')
  if (!colorLocation) {
    console.error('Unable to get the location of the color uniform')
    return
  }
  gl.uniform4fv(colorLocation, new Float32Array([0.0, 0.8, 0.0, 1.0]))

  // I wanna run this first, before everything else, but I'll leave it here for now

  await gl.makeXRCompatible()

  const xr: XRSystem | undefined = navigator.xr
  if (!xr) {
    console.error('WebXR not supported')
    return
  }

  const isWebXRSupported: boolean = await xr.isSessionSupported('immersive-ar')
  if (!isWebXRSupported) {
    console.error('WebXR not supported')
    return
  }

  // Application core
  // MAKE IT WORK MAKE IT RIGHT MAKE IT FAST

  const CUBE = [
    -0.1, -0.1, 0.1,
    0.1, -0.1, 0.1,
    0.1, 0.1, 0.1,
    -0.1, -0.1, 0.1,
    0.1, 0.1, 0.1,
    -0.1, 0.1, 0.1,

    0.1, -0.1, -0.1,
    -0.1, -0.1, -0.1,
    -0.1, 0.1, -0.1,
    0.1, -0.1, -0.1,
    -0.1, 0.1, -0.1,
    0.1, 0.1, -0.1,

    0.1, -0.1, 0.1,
    0.1, -0.1, -0.1,
    0.1, 0.1, -0.1,
    0.1, -0.1, 0.1,
    0.1, 0.1, -0.1,
    0.1, 0.1, 0.1,

    -0.1, -0.1, -0.1,
    -0.1, -0.1, 0.1,
    -0.1, 0.1, 0.1,
    -0.1, -0.1, -0.1,
    -0.1, 0.1, 0.1,
    -0.1, 0.1, -0.1,

    -0.1, 0.1, 0.1,
    0.1, 0.1, 0.1,
    0.1, 0.1, -0.1,
    -0.1, 0.1, 0.1,
    0.1, 0.1, -0.1,
    -0.1, 0.1, -0.1,

    -0.1, -0.1, -0.1,
    0.1, -0.1, -0.1,
    0.1, -0.1, 0.1,
    -0.1, -0.1, -0.1,
    0.1, -0.1, 0.1,
    -0.1, -0.1, 0.1
  ];

  const cubeVAO: WebGLVertexArrayObject = gl.createVertexArray()
  const cubeBuffer: WebGLBuffer = gl.createBuffer()

  gl.bindVertexArray(cubeVAO)
  gl.bindBuffer(gl.ARRAY_BUFFER, cubeBuffer)

  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(CUBE), gl.STATIC_DRAW)

  gl.vertexAttribPointer(positionLocation, BASE_NUMBER_OF_DIMENSIONS, gl.FLOAT, false, 0, 0)
  gl.enableVertexAttribArray(positionLocation)

  const cubePosition: Float32Array = new Float32Array([0.0, 0.0, -0.5])
  const cubeRotation: Float32Array = new Float32Array([0.0, 0.0, 0.0])
  const cubeScale: Float32Array = new Float32Array([1.0, 1.0, 1.0])

  // Hands skeleton joint index buffer

  const handSkeletonJointIndicesBuffer: WebGLBuffer = gl.createBuffer()
  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, handSkeletonJointIndicesBuffer)
  gl.bufferData(
    gl.ELEMENT_ARRAY_BUFFER,
    new Uint16Array(HAND_SKELETON_BY_JOINT_INDICES),
    gl.STATIC_DRAW
  )

  // Left hand

  const leftHandVAO: WebGLVertexArrayObject = gl.createVertexArray()
  const leftHandBuffer: WebGLBuffer = gl.createBuffer()

  gl.bindVertexArray(leftHandVAO)
  gl.bindBuffer(gl.ARRAY_BUFFER, leftHandBuffer)

  gl.bufferData(
    gl.ARRAY_BUFFER,
    new Float32Array(new Array(NUMBER_OF_HAND_JOINT_DIMENSIONS).fill(0)),
    gl.DYNAMIC_DRAW
  )

  gl.vertexAttribPointer(positionLocation, BASE_NUMBER_OF_DIMENSIONS, gl.FLOAT, false, 0, 0)
  gl.enableVertexAttribArray(positionLocation)

  // Left hand skeleton

  const leftHandSkeletonVAO: WebGLVertexArrayObject = gl.createVertexArray()
  gl.bindVertexArray(leftHandSkeletonVAO)
  gl.bindBuffer(gl.ARRAY_BUFFER, leftHandBuffer)

  gl.vertexAttribPointer(positionLocation, BASE_NUMBER_OF_DIMENSIONS, gl.FLOAT, false, 0, 0)
  gl.enableVertexAttribArray(positionLocation)

  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, handSkeletonJointIndicesBuffer)

  // Right hand

  const rightHandVAO: WebGLVertexArrayObject = gl.createVertexArray()
  const rightHandBuffer: WebGLBuffer = gl.createBuffer()

  gl.bindVertexArray(rightHandVAO)
  gl.bindBuffer(gl.ARRAY_BUFFER, rightHandBuffer)

  gl.bufferData(
    gl.ARRAY_BUFFER,
    new Float32Array(new Array(NUMBER_OF_HAND_JOINT_DIMENSIONS).fill(0)),
    gl.DYNAMIC_DRAW
  )

  gl.vertexAttribPointer(positionLocation, BASE_NUMBER_OF_DIMENSIONS, gl.FLOAT, false, 0, 0)
  gl.enableVertexAttribArray(positionLocation)

  // Right hand skeleton

  const rightHandSkeletonVAO: WebGLVertexArrayObject = gl.createVertexArray()
  gl.bindVertexArray(rightHandSkeletonVAO)
  gl.bindBuffer(gl.ARRAY_BUFFER, rightHandBuffer)

  gl.vertexAttribPointer(positionLocation, BASE_NUMBER_OF_DIMENSIONS, gl.FLOAT, false, 0, 0)
  gl.enableVertexAttribArray(positionLocation)

  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, handSkeletonJointIndicesBuffer)

  console.log('Program loaded successfully, waiting for user to start the experience')

  // ...

  const startVRExperience = async () => {
    const xrSession: XRSession = await xr.requestSession(
      'immersive-ar',
      { optionalFeatures: ['hit-test', 'hand-tracking'] }
    )

    if (!xrSession) {
      console.error('Failed to start XR session')
      return
    }

    const xrGLLayer: XRWebGLLayer = new XRWebGLLayer(xrSession, gl)
    xrSession.updateRenderState({
      baseLayer: xrGLLayer,
    })

    const referenceSpace: XRReferenceSpace | XRBoundedReferenceSpace = await xrSession.requestReferenceSpace('local')

    const drawingVertices: Float32Array = new Float32Array()

    const onXRFrame: XRFrameRequestCallback = (time: DOMHighResTimeStamp, frame: XRFrame) => {
      const leftHandVertices: Float32Array = new Float32Array(NUMBER_OF_HAND_JOINT_DIMENSIONS).fill(0)
      const rightHandVertices: Float32Array = new Float32Array(NUMBER_OF_HAND_JOINT_DIMENSIONS).fill(0)

      for (const inputSource of xrSession.inputSources) {
        if (!inputSource.hand) continue

        const isLeft: boolean = inputSource.handedness === 'left'
        const verticesReference: Float32Array = isLeft ? leftHandVertices : rightHandVertices
        for (const [jointName, jointSpace] of inputSource.hand) {
          const jointPose: XRJointPose | undefined = frame.getJointPose?.(jointSpace, referenceSpace)
          if (!jointPose) continue

          const handJointIndex: number = HAND_JOINT_INDICES_BY_NAME[jointName]
          if (handJointIndex === undefined) continue

          verticesReference[handJointIndex * 3] = jointPose.transform.position.x
          verticesReference[handJointIndex * 3 + 1] = jointPose.transform.position.y
          verticesReference[handJointIndex * 3 + 2] = jointPose.transform.position.z
        }
      }

      gl.bindBuffer(gl.ARRAY_BUFFER, leftHandBuffer)
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, new Float32Array(leftHandVertices), 0, leftHandVertices.length)

      gl.bindBuffer(gl.ARRAY_BUFFER, rightHandBuffer)
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, new Float32Array(rightHandVertices), 0, rightHandVertices.length)

      if (leftHandVertices.length) {
        const leftHandIndexFingerTipIndex: Float32Array = leftHandVertices.subarray(
          HAND_JOINT_INDICES_BY_NAME['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS,
          HAND_JOINT_INDICES_BY_NAME['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
        )
        const leftHandThumbTipIndex: Float32Array = leftHandVertices.subarray(
          HAND_JOINT_INDICES_BY_NAME['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS,
          HAND_JOINT_INDICES_BY_NAME['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
        )
        const distanceBetweenLeftHandIndexFingerTipAndThumbTip: number = Math.sqrt(
          (leftHandIndexFingerTipIndex[0] - leftHandThumbTipIndex[0]) ** 2 +
          (leftHandIndexFingerTipIndex[1] - leftHandThumbTipIndex[1]) ** 2 +
          (leftHandIndexFingerTipIndex[2] - leftHandThumbTipIndex[2]) ** 2
        )
        console.log('Distance between left hand index finger tip and thumb tip:', distanceBetweenLeftHandIndexFingerTipAndThumbTip)
        if (distanceBetweenLeftHandIndexFingerTipAndThumbTip < 0.02) {
          // CODE Interactions
          // Take the cube position and update it based on the difference between the start of the event and the end
        }
      }

      if (rightHandVertices.length) {
        const rightHandIndexFingerTipIndex: Float32Array = rightHandVertices.subarray(
          HAND_JOINT_INDICES_BY_NAME['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS,
          HAND_JOINT_INDICES_BY_NAME['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
        )
        const rightHandThumbTipIndex: Float32Array = rightHandVertices.subarray(
          HAND_JOINT_INDICES_BY_NAME['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS,
          HAND_JOINT_INDICES_BY_NAME['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
        )
        const distanceBetweenrightHandIndexFingerTipAndThumbTip: number = Math.sqrt(
          (rightHandIndexFingerTipIndex[0] - rightHandThumbTipIndex[0]) ** 2 +
          (rightHandIndexFingerTipIndex[1] - rightHandThumbTipIndex[1]) ** 2 +
          (rightHandIndexFingerTipIndex[2] - rightHandThumbTipIndex[2]) ** 2
        )
        if (distanceBetweenrightHandIndexFingerTipAndThumbTip < 0.02) {
        }
      }

      const pose: XRViewerPose | undefined = frame.getViewerPose(referenceSpace)
      if (!pose) {
        xrSession.requestAnimationFrame(onXRFrame)
        return
      }

      gl.bindFramebuffer(gl.FRAMEBUFFER, xrGLLayer.framebuffer)

      gl.clearColor(0.0, 0.0, 0.0, 0.3)
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

      for (const view of pose.views) {
        const viewport: XRViewport | undefined = xrGLLayer.getViewport(view)
        if (!viewport) continue

        gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height)

        gl.uniformMatrix4fv(projectionLocation, false, view.projectionMatrix)
        gl.uniformMatrix4fv(viewLocation, false, view.transform.inverse.matrix)
        gl.uniformMatrix4fv(modelLocation, false, new Float32Array(IDENTITY_MATRIX))

        gl.bindVertexArray(leftHandVAO)
        gl.drawArrays(gl.POINTS, 0, NUMBER_OF_JOINTS_PER_HAND)

        gl.bindVertexArray(leftHandSkeletonVAO)
        gl.drawElements(gl.LINES, HAND_SKELETON_BY_JOINT_INDICES.length, gl.UNSIGNED_SHORT, 0)

        gl.bindVertexArray(rightHandVAO)
        gl.drawArrays(gl.POINTS, 0, NUMBER_OF_JOINTS_PER_HAND)

        gl.bindVertexArray(rightHandSkeletonVAO)
        gl.drawElements(gl.LINES, HAND_SKELETON_BY_JOINT_INDICES.length, gl.UNSIGNED_SHORT, 0)

        // render the scene graphic data
        // For each model take the corresponding matrices and multiply them here, then pass the resulting matrix to the shader and render the model
        // CODE
        gl.bindVertexArray(cubeVAO)
        gl.drawArrays(gl.POINTS, 0, CUBE.length / BASE_NUMBER_OF_DIMENSIONS)
      }

      xrSession.requestAnimationFrame(onXRFrame)
    }

    xrSession.requestAnimationFrame(onXRFrame)
  }

  const startExperienceButton: HTMLButtonElement | null = (
    document.getElementById('start-experience') as HTMLButtonElement | null
  )
  if (!startExperienceButton) {
    console.error('Start experience button not found')
    return
  }
  startExperienceButton.onclick = startVRExperience
})()
