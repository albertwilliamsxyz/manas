// utils-js
const generateRandomColor = () => [
  Math.random(),
  Math.random(),
  Math.random(),
  1,
];

const BASE_NUMBER_OF_DIMENSIONS = 3;

const NUMBER_OF_JOINTS_PER_HAND = 25;

const HAND_SKELETON_BY_JOINT_INDICES = [
  0, 1, 1, 2, 2, 3, 3, 4,
  0, 5, 5, 6, 6, 7, 7, 8, 8, 9,
  0, 10, 10, 11, 11, 12, 12, 13, 13, 14,
  0, 15, 15, 16, 16, 17, 17, 18, 18, 19,
  0, 20, 20, 21, 21, 22, 22, 23, 23, 24
];

const jointToIndex = {
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
};

const cubeVertices = new Float32Array([
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
]);

const WEBGL_2_VERSION_DECLARATION = '#version 300 es';

const VERTEX_SHADER_SOURCE = WEBGL_2_VERSION_DECLARATION + `
in vec3 a_position;
uniform mat4 u_projection;
uniform mat4 u_view;
void main() {
  gl_Position = u_projection * u_view * vec4(a_position, 1.0);
  gl_PointSize = 10.0;
}
`;

const FRAGMENT_SHADER_SHOURCE = WEBGL_2_VERSION_DECLARATION + `
precision highp float;
out vec4 outColor;
uniform vec4 u_color;
void main() {
  outColor = u_color;
}
`;

// webgl-utils
const createShader = (gl, type, source) => {
  const vertexShader = gl.createShader(type);
  gl.shaderSource(vertexShader, source);
  gl.compileShader(vertexShader);
  if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) {
    alert(`There was an error while compiling the ${type} shader`);
    alert(gl.getShaderInfoLog(vertexShader));
    gl.deleteShader(vertexShader);
    return;
  }
  return vertexShader;
}

// webgl-utils
const createProgram = (gl, shaders) => {
  const program = gl.createProgram();
  for (const shader of shaders) {
    gl.attachShader(program, shader);
  }
  gl.linkProgram(program);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    alert('Error while linking the program');
    alert(gl.getProgramInfoLog(program));
    gl.deleteProgram(program);
    return;
  }
  gl.useProgram(program);
  return program;
}

const main = async () => {
  /** @type {WebGL2RenderingContext} */
  const gl = application.getContext('webgl2');
  await gl.makeXRCompatible();

  if (!gl) {
    alert('WebGL2 not supported');
    return;
  }

  const isWebXRSupported = await navigator.xr.isSessionSupported('immersive-ar');
  if (!isWebXRSupported) {
    alert('WebXR not supported');
    return;
  }

  const vertexShader = createShader(gl, gl.VERTEX_SHADER, VERTEX_SHADER_SOURCE);
  if (!vertexShader) return;

  const fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, FRAGMENT_SHADER_SHOURCE);
  if (!fragmentShader) return;

  gl.enable(gl.DEPTH_TEST);

  const program = createProgram(gl, [vertexShader, fragmentShader]);

  const positionAttributeLocation = gl.getAttribLocation(program, 'a_position');

  // Declaration of resources for the main model

  const mainModelBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, mainModelBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, cubeVertices, gl.STATIC_DRAW);
  const numberOfVerticesInMainModel = cubeVertices.length / BASE_NUMBER_OF_DIMENSIONS;

  const mainModelVAO = gl.createVertexArray();
  gl.bindVertexArray(mainModelVAO);

  gl.vertexAttribPointer(
    positionAttributeLocation,
    BASE_NUMBER_OF_DIMENSIONS,
    gl.FLOAT,
    false,
    0,
    0
  );
  gl.enableVertexAttribArray(positionAttributeLocation);

  // Declaration of resources for the hand models

  // Left hand

  const leftHandBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, leftHandBuffer);
  gl.bufferData(
    gl.ARRAY_BUFFER,
    new Float32Array(
      new Array(NUMBER_OF_JOINTS_PER_HAND * BASE_NUMBER_OF_DIMENSIONS).fill(0)
    ),
    gl.DYNAMIC_DRAW
  );

  const leftHandVAO = gl.createVertexArray();
  gl.bindVertexArray(leftHandVAO);

  gl.vertexAttribPointer(
    positionAttributeLocation,
    BASE_NUMBER_OF_DIMENSIONS,
    gl.FLOAT,
    false,
    0,
    0
  );
  gl.enableVertexAttribArray(positionAttributeLocation);

  // Right hand

  const rightHandBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, rightHandBuffer);
  gl.bufferData(
    gl.ARRAY_BUFFER,
    new Float32Array(
      new Array(NUMBER_OF_JOINTS_PER_HAND * BASE_NUMBER_OF_DIMENSIONS).fill(0)
    ),
    gl.DYNAMIC_DRAW
  );

  const rightHandVAO = gl.createVertexArray();
  gl.bindVertexArray(rightHandVAO);

  gl.vertexAttribPointer(
    positionAttributeLocation,
    BASE_NUMBER_OF_DIMENSIONS,
    gl.FLOAT,
    false,
    0,
    0
  );
  gl.enableVertexAttribArray(positionAttributeLocation);

  // Hands skeleton joint index buffer

  const handSkeletonJointIndicesBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, handSkeletonJointIndicesBuffer);
  gl.bufferData(
    gl.ELEMENT_ARRAY_BUFFER,
    new Uint16Array(HAND_SKELETON_BY_JOINT_INDICES),
    gl.STATIC_DRAW
  );

  // Left hand skeleton

  const leftHandSkeletonVAO = gl.createVertexArray();
  gl.bindVertexArray(leftHandSkeletonVAO);

  gl.bindBuffer(gl.ARRAY_BUFFER, leftHandBuffer);
  gl.vertexAttribPointer(
    positionAttributeLocation,
    BASE_NUMBER_OF_DIMENSIONS,
    gl.FLOAT,
    false,
    0,
    0
  );
  gl.enableVertexAttribArray(positionAttributeLocation);

  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, handSkeletonJointIndicesBuffer);

  // Right hand skeleton

  const rightHandSkeletonVAO = gl.createVertexArray();
  gl.bindVertexArray(rightHandSkeletonVAO);

  gl.bindBuffer(gl.ARRAY_BUFFER, rightHandBuffer);
  gl.vertexAttribPointer(
    positionAttributeLocation,
    BASE_NUMBER_OF_DIMENSIONS,
    gl.FLOAT,
    false,
    0,
    0
  );
  gl.enableVertexAttribArray(positionAttributeLocation);

  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, handSkeletonJointIndicesBuffer);

  // Drawings

  const drawingBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, drawingBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(), gl.DYNAMIC_DRAW);

  const drawingVAO = gl.createVertexArray();
  gl.bindVertexArray(drawingVAO);

  gl.vertexAttribPointer(
    positionAttributeLocation,
    BASE_NUMBER_OF_DIMENSIONS,
    gl.FLOAT,
    false,
    0,
    0
  );
  gl.enableVertexAttribArray(positionAttributeLocation);

  // Set up of the projection and view matrices

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

  const colorLocation = gl.getUniformLocation(program, 'u_color');
  gl.uniform4fv(colorLocation, new Float32Array(generateRandomColor()));

  startVRButton.onclick = async () => {
    const xrSession = await navigator.xr.requestSession('immersive-ar', {
      optionalFeatures: [
        'hand-tracking',
      ]
    });

    if (!xrSession) {
      alert('Failed to start XR session');
      return;
    }

    const xrGLLayer = new XRWebGLLayer(xrSession, gl);
    xrSession.updateRenderState({
      baseLayer: xrGLLayer,
    });

    const referenceSpace = await xrSession.requestReferenceSpace('local');

    const drawingVertices = [];

    const onXRFrame = (time, xrFrame) => {
      const leftHandVertices = new Float32Array(NUMBER_OF_JOINTS_PER_HAND * BASE_NUMBER_OF_DIMENSIONS).fill(0);
      const rightHandVertices = new Float32Array(NUMBER_OF_JOINTS_PER_HAND * BASE_NUMBER_OF_DIMENSIONS).fill(0);

      for (const inputSource of xrSession.inputSources) {
        if (!inputSource.hand) continue;

        const isLeft = inputSource.handedness === 'left';
        const verticesReference = isLeft ? leftHandVertices : rightHandVertices;
        for (const [jointName, jointSpace] of inputSource.hand) {
          const jointPose = xrFrame.getJointPose(jointSpace, referenceSpace);
          if (!jointPose) continue;

          const index = jointToIndex[jointName];
          if (index === undefined) continue;

          verticesReference[index * 3] = jointPose.transform.position.x;
          verticesReference[index * 3 + 1] = jointPose.transform.position.y;
          verticesReference[index * 3 + 2] = jointPose.transform.position.z;
        }
      }

      gl.bindBuffer(gl.ARRAY_BUFFER, leftHandBuffer);
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, new Float32Array(leftHandVertices), 0, leftHandVertices.length);

      gl.bindBuffer(gl.ARRAY_BUFFER, rightHandBuffer);
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, new Float32Array(rightHandVertices), 0, rightHandVertices.length);

      if (leftHandVertices.length) {
        const leftHandIndexFingerTipIndex = leftHandVertices.subarray(
          jointToIndex['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS,
          jointToIndex['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
        );
        const leftHandThumbTipIndex = leftHandVertices.subarray(
          jointToIndex['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS,
          jointToIndex['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
        );
        const distanceBetweenLeftHandIndexFingerTipAndThumbTip = Math.sqrt(
          (leftHandIndexFingerTipIndex[0] - leftHandThumbTipIndex[0]) ** 2 +
          (leftHandIndexFingerTipIndex[1] - leftHandThumbTipIndex[1]) ** 2 +
          (leftHandIndexFingerTipIndex[2] - leftHandThumbTipIndex[2]) ** 2
        );
        console.log('Distance between left hand index finger tip and thumb tip:', distanceBetweenLeftHandIndexFingerTipAndThumbTip);
        if (distanceBetweenLeftHandIndexFingerTipAndThumbTip < 0.016) {
          drawingVertices.push(...leftHandIndexFingerTipIndex);
        }
      }

      if (rightHandVertices.length) {
        const rightHandIndexFingerTipIndex = rightHandVertices.subarray(
          jointToIndex['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS,
          jointToIndex['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
        );
        const rightHandThumbTipIndex = rightHandVertices.subarray(
          jointToIndex['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS,
          jointToIndex['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
        );
        const distanceBetweenrightHandIndexFingerTipAndThumbTip = Math.sqrt(
          (rightHandIndexFingerTipIndex[0] - rightHandThumbTipIndex[0]) ** 2 +
          (rightHandIndexFingerTipIndex[1] - rightHandThumbTipIndex[1]) ** 2 +
          (rightHandIndexFingerTipIndex[2] - rightHandThumbTipIndex[2]) ** 2
        );
        if (distanceBetweenrightHandIndexFingerTipAndThumbTip < 0.016) {
          gl.uniform4fv(colorLocation, new Float32Array(generateRandomColor()));
        }
      }

      gl.bindBuffer(gl.ARRAY_BUFFER, drawingBuffer);
      gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(drawingVertices), gl.DYNAMIC_DRAW);

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

        gl.bindVertexArray(mainModelVAO);
        gl.drawArrays(gl.POINTS, 0, numberOfVerticesInMainModel);
        gl.drawArrays(gl.LINE_LOOP, 0, numberOfVerticesInMainModel);

        gl.bindVertexArray(leftHandVAO);
        gl.drawArrays(gl.POINTS, 0, NUMBER_OF_JOINTS_PER_HAND);

        gl.bindVertexArray(leftHandSkeletonVAO);
        gl.drawElements(gl.LINES, HAND_SKELETON_BY_JOINT_INDICES.length, gl.UNSIGNED_SHORT, 0);

        gl.bindVertexArray(rightHandVAO);
        gl.drawArrays(gl.POINTS, 0, NUMBER_OF_JOINTS_PER_HAND);

        gl.bindVertexArray(rightHandSkeletonVAO);
        gl.drawElements(gl.LINES, HAND_SKELETON_BY_JOINT_INDICES.length, gl.UNSIGNED_SHORT, 0);

        gl.bindVertexArray(drawingVAO);
        gl.drawArrays(gl.POINTS, 0, drawingVertices.length / BASE_NUMBER_OF_DIMENSIONS);
      }

      xrSession.requestAnimationFrame(onXRFrame);
    }

    xrSession.requestAnimationFrame(onXRFrame);
  };
}

await main()
