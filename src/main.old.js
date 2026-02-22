const createNewArray = (size) => new Array(size).fill(null)

const generateRandomId = () => ((new Date()).getTime() + Math.random()).toString();

const generateRandomPosition = () => Math.random() - 0.5

const IDENTITY_MATRIX = [
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1
];

const CUBE_MODEL_NAME = 'cube'
const CUBE_MODEL_VERTICES = [
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

let MODELS = {
  [CUBE_MODEL_NAME]: {
    vertices: CUBE_MODEL_VERTICES,
  }
}


// utils-js
const generateRandomColor = () => [
  Math.random(),
  Math.random(),
  Math.random(),
  1,
];

const BASE_NUMBER_OF_DIMENSIONS = 3;

const NUMBER_OF_JOINTS_PER_HAND = 25;
const NUMBER_OF_HAND_JOINT_DIMENSIONS = NUMBER_OF_JOINTS_PER_HAND * BASE_NUMBER_OF_DIMENSIONS

const HAND_SKELETON_BY_JOINT_INDICES = [
  0, 1, 1, 2, 2, 3, 3, 4,
  0, 5, 5, 6, 6, 7, 7, 8, 8, 9,
  0, 10, 10, 11, 11, 12, 12, 13, 13, 14,
  0, 15, 15, 16, 16, 17, 17, 18, 18, 19,
  0, 20, 20, 21, 21, 22, 22, 23, 23, 24
];

const HAND_JOINT_INDICES_BY_NAME = {
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

const WEBGL_2_VERSION_DECLARATION = '#version 300 es';

const VERTEX_SHADER_SOURCE = WEBGL_2_VERSION_DECLARATION + `
in vec3 a_position;
uniform mat4 u_projection;
uniform mat4 u_view;
uniform mat4 u_model;
void main() {
  gl_Position = u_projection * u_view * u_model * vec4(a_position, 1.0);
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

const createShader = (gl, type, source) => {
  const vertexShader = gl.createShader(type);
  gl.shaderSource(vertexShader, source);
  gl.compileShader(vertexShader);
  if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) {
    console.error(`There was an error while compiling the ${type} shader`);
    console.error(gl.getShaderInfoLog(vertexShader));
    gl.deleteShader(vertexShader);
    return;
  }
  return vertexShader;
}

const createProgram = (gl, shaders) => {
  const program = gl.createProgram();
  for (const shader of shaders) {
    gl.attachShader(program, shader);
  }
  gl.linkProgram(program);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    console.error('Error while linking the program');
    console.error(gl.getProgramInfoLog(program));
    gl.deleteProgram(program);
    return;
  }
  gl.useProgram(program);
  return program;
}

const createGraphicLayer = async (application) => {
  const gl = application.getContext('webgl2');
  if (!gl) {
    console.error('WebGL2 not supported');
    return;
  }

  await gl.makeXRCompatible();

  const isWebXRSupported = await navigator.xr.isSessionSupported('immersive-ar');
  if (!isWebXRSupported) {
    console.error('WebXR not supported');
    return;
  }

  const vertexShader = createShader(gl, gl.VERTEX_SHADER, VERTEX_SHADER_SOURCE);
  if (!vertexShader) return;

  const fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, FRAGMENT_SHADER_SHOURCE);
  if (!fragmentShader) return;

  gl.enable(gl.DEPTH_TEST);

  const program = createProgram(gl, [vertexShader, fragmentShader]);

  return { gl, program }
}

// CORE LAYER

const createSceneObjects = () => new Map()
const createSceneObject = (
  modelName = CUBE_MODEL_NAME,
  position = [0, 0, 0],
  rotation = [0, 0, 0],
  scale = [1, 1, 1]
) => ({
  id: generateRandomId(),
  modelName,
  position,
  rotation,
  scale,
})

const addSceneObject = (sceneObjects, sceneObject) => {
  const newSceneObjects = new Map(sceneObjects)
  newSceneObjects.set(sceneObject.id, sceneObject)
  return newSceneObjects
}

// GRAPHIC LAYER

const createSceneObjectsGraphicData = () => new Map()
const createSceneObjectGraphicData = (gl, sceneObject, positionAttributeLocation) => {
  const model = new Float32Array(MODELS[sceneObject.modelName])
  const sceneObjectVAO = gl.createVertexArray();
  const sceneObjectBuffer = gl.createBuffer();

  gl.bindVertexArray(sceneObjectVAO);
  gl.bindBuffer(gl.ARRAY_BUFFER, sceneObjectBuffer);

  gl.bufferData(gl.ARRAY_BUFFER, model, gl.STATIC_DRAW);
  gl.vertexAttribPointer(positionAttributeLocation, BASE_NUMBER_OF_DIMENSIONS, gl.FLOAT, false, 0, 0);
  gl.enableVertexAttribArray(positionAttributeLocation);

  return {
    sceneObjectId: sceneObject.id,
    buffer: sceneObjectBuffer,
    vao: sceneObjectVAO,
    numberOfVertices: model.length / BASE_NUMBER_OF_DIMENSIONS
  };
}

const addSceneObjectGraphic = (sceneObjectsGraphicData, sceneObjectGraphicData) => {
  const newSceneObjectsGraphicData = new Map(sceneObjectsGraphicData)
  newSceneObjectsGraphicData.set(sceneObjectGraphicData.sceneObjectId, sceneObjectGraphicData)
  return newSceneObjectsGraphicData
}

const drawSceneObject = (gl, modelLocation, sceneObjects, sceneObjectGraphicData) => {
  const sceneObjectId = sceneObjectGraphicData.sceneObjectId
  const sceneObject = sceneObjects.get(sceneObjectId)

  const transformationMatrix = composeModelMatrix(
    sceneObject.position,
    sceneObject.rotation,
    sceneObject.scale
  );
  gl.uniformMatrix4fv(modelLocation, false, new Float32Array(IDENTITY_MATRIX));

  gl.bindVertexArray(sceneObjectGraphicData.vao);
  gl.drawArrays(gl.POINTS, 0, sceneObjectGraphicData.numberOfVertices);
  gl.drawArrays(gl.LINE_LOOP, 0, sceneObjectGraphicData.numberOfVertices);
}

const drawAllSceneObjects = (gl, modelLocation, sceneObjects, sceneObjectsGraphicData) => {
  // Aqui pudiera usar el ID directamente y mantenerlos asi sincronizados
  sceneObjectsGraphicData.forEach((sceneObjectGraphicData, _) => {
    drawSceneObject(gl, modelLocation, sceneObjects, sceneObjectGraphicData)
  })
}

const createScaleMatrix = ([sx, sy, sz]) => {
  return [
    sx, 0, 0, 0,
    0, sy, 0, 0,
    0, 0, sz, 0,
    0, 0, 0, 1
  ];
}

const createRotationXMatrix = (rx) => {
  const c = Math.cos(rx), s = Math.sin(rx);
  return [
    1, 0, 0, 0,
    0, c, -s, 0,
    0, s, c, 0,
    0, 0, 0, 1
  ];
}

const createRotationYMatrix = (ry) => {
  const c = Math.cos(ry), s = Math.sin(ry);
  return [
    c, 0, s, 0,
    0, 1, 0, 0,
    -s, 0, c, 0,
    0, 0, 0, 1
  ];
}

const createRotationZMatrix = (rz) => {
  const c = Math.cos(rz), s = Math.sin(rz);
  return [
    c, -s, 0, 0,
    s, c, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  ];
}

const createTranslationMatrix = ([tx, ty, tz]) => {
  return [
    1, 0, 0, tx,
    0, 1, 0, ty,
    0, 0, 1, tz,
    0, 0, 0, 1
  ];
}

const multiplyMatrices = (a, b) => {
  const result = new Array(16).fill(0);
  for (let row = 0; row < 4; ++row) {
    for (let col = 0; col < 4; ++col) {
      for (let i = 0; i < 4; ++i) {
        result[row * 4 + col] += a[row * 4 + i] * b[i * 4 + col];
      }
    }
  }
  return result;
}

const composeModelMatrix = (position, rotation, scale) => {
  let model = createScaleMatrix(scale);
  model = multiplyMatrices(createRotationXMatrix(rotation[0]), model);
  model = multiplyMatrices(createRotationYMatrix(rotation[1]), model);
  model = multiplyMatrices(createRotationZMatrix(rotation[2]), model);
  model = multiplyMatrices(createTranslationMatrix(position), model);
  return model;
}

const getGraphicLayerLocations = (gl, program) => {
  const positionLocation = gl.getAttribLocation(program, 'a_position');

  const projectionLocation = gl.getUniformLocation(program, 'u_projection');
  gl.uniformMatrix4fv(projectionLocation, false, new Float32Array(IDENTITY_MATRIX));

  const viewLocation = gl.getUniformLocation(program, 'u_view');
  gl.uniformMatrix4fv(viewLocation, false, new Float32Array(IDENTITY_MATRIX));

  const modelLocation = gl.getUniformLocation(program, 'u_model');
  gl.uniformMatrix4fv(modelLocation, false, new Float32Array(IDENTITY_MATRIX));

  const colorLocation = gl.getUniformLocation(program, 'u_color');
  gl.uniform4fv(colorLocation, new Float32Array(generateRandomColor()));

  return {
    positionLocation,
    projectionLocation,
    viewLocation,
    modelLocation,
    colorLocation
  }
}

const main = async () => {
  const { gl, program } = await createGraphicLayer(application);

  if (!gl || !program) {
    console.error('Failed to create graphic layer');
    return;
  }

  const {
    positionLocation,
    projectionLocation,
    viewLocation,
    modelLocation,
    colorLocation
  } = getGraphicLayerLocations(gl, program);

  let sceneObjects = createSceneObjects()
  let sceneObjectsGraphicData = createSceneObjectsGraphicData()

  const randomScenePosition = createNewArray(3).map(generateRandomPosition)

  const sceneObject = createSceneObject(CUBE_MODEL_NAME, randomScenePosition)
  sceneObjects = addSceneObject(sceneObjects, sceneObject)

  const sceneObjectGraphicData = createSceneObjectGraphicData(gl, sceneObject, positionLocation)
  sceneObjectsGraphicData = addSceneObjectGraphic(sceneObjectsGraphicData, sceneObjectGraphicData)

  // I want to create a function that transforms every vertice in the buffer and then 

  // Left hand

  const leftHandVAO = gl.createVertexArray();
  const leftHandBuffer = gl.createBuffer();

  gl.bindVertexArray(leftHandVAO);
  gl.bindBuffer(gl.ARRAY_BUFFER, leftHandBuffer);

  gl.bufferData(
    gl.ARRAY_BUFFER,
    new Float32Array(new Array(NUMBER_OF_HAND_JOINT_DIMENSIONS).fill(0)),
    gl.DYNAMIC_DRAW
  );

  gl.vertexAttribPointer(
    positionLocation,
    BASE_NUMBER_OF_DIMENSIONS,
    gl.FLOAT,
    false,
    0,
    0
  );
  gl.enableVertexAttribArray(positionLocation);

  // Right hand

  const rightHandVAO = gl.createVertexArray();
  const rightHandBuffer = gl.createBuffer();

  gl.bindVertexArray(rightHandVAO);
  gl.bindBuffer(gl.ARRAY_BUFFER, rightHandBuffer);

  gl.bufferData(
    gl.ARRAY_BUFFER,
    new Float32Array(new Array(NUMBER_OF_HAND_JOINT_DIMENSIONS).fill(0)),
    gl.DYNAMIC_DRAW
  );

  gl.vertexAttribPointer(
    positionLocation,
    BASE_NUMBER_OF_DIMENSIONS,
    gl.FLOAT,
    false,
    0,
    0
  );
  gl.enableVertexAttribArray(positionLocation);

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
    positionLocation,
    BASE_NUMBER_OF_DIMENSIONS,
    gl.FLOAT,
    false,
    0,
    0
  );
  gl.enableVertexAttribArray(positionLocation);

  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, handSkeletonJointIndicesBuffer);

  // Right hand skeleton

  const rightHandSkeletonVAO = gl.createVertexArray();

  gl.bindVertexArray(rightHandSkeletonVAO);
  gl.bindBuffer(gl.ARRAY_BUFFER, rightHandBuffer);

  gl.vertexAttribPointer(
    positionLocation,
    BASE_NUMBER_OF_DIMENSIONS,
    gl.FLOAT,
    false,
    0,
    0
  );
  gl.enableVertexAttribArray(positionLocation);

  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, handSkeletonJointIndicesBuffer);

  // Drawings

  const drawingVAO = gl.createVertexArray();
  const drawingBuffer = gl.createBuffer();

  gl.bindVertexArray(drawingVAO);
  gl.bindBuffer(gl.ARRAY_BUFFER, drawingBuffer);

  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(), gl.DYNAMIC_DRAW);

  gl.vertexAttribPointer(
    positionLocation,
    BASE_NUMBER_OF_DIMENSIONS,
    gl.FLOAT,
    false,
    0,
    0
  );
  gl.enableVertexAttribArray(positionLocation);

  // Set up of the projection and view matrices

  startVRButton.onclick = async () => {
    const xrSession = await navigator.xr.requestSession('immersive-ar', {
      optionalFeatures: [
        'hand-tracking',
      ]
    });

    if (!xrSession) {
      console.error('Failed to start XR session');
      return;
    }

    const xrGLLayer = new XRWebGLLayer(xrSession, gl);
    xrSession.updateRenderState({
      baseLayer: xrGLLayer,
    });

    const referenceSpace = await xrSession.requestReferenceSpace('local');

    const drawingVertices = [];

    const onXRFrame = (time, xrFrame) => {
      const leftHandVertices = new Float32Array(NUMBER_OF_HAND_JOINT_DIMENSIONS).fill(0);
      const rightHandVertices = new Float32Array(NUMBER_OF_HAND_JOINT_DIMENSIONS).fill(0);

      for (const inputSource of xrSession.inputSources) {
        if (!inputSource.hand) continue;

        const isLeft = inputSource.handedness === 'left';
        const verticesReference = isLeft ? leftHandVertices : rightHandVertices;
        for (const [jointName, jointSpace] of inputSource.hand) {
          const jointPose = xrFrame.getJointPose(jointSpace, referenceSpace);
          if (!jointPose) continue;

          const index = HAND_JOINT_INDICES_BY_NAME[jointName];
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
          HAND_JOINT_INDICES_BY_NAME['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS,
          HAND_JOINT_INDICES_BY_NAME['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
        );
        const leftHandThumbTipIndex = leftHandVertices.subarray(
          HAND_JOINT_INDICES_BY_NAME['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS,
          HAND_JOINT_INDICES_BY_NAME['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
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
          HAND_JOINT_INDICES_BY_NAME['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS,
          HAND_JOINT_INDICES_BY_NAME['index-finger-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
        );
        const rightHandThumbTipIndex = rightHandVertices.subarray(
          HAND_JOINT_INDICES_BY_NAME['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS,
          HAND_JOINT_INDICES_BY_NAME['thumb-tip'] * BASE_NUMBER_OF_DIMENSIONS + BASE_NUMBER_OF_DIMENSIONS
        );
        const distanceBetweenrightHandIndexFingerTipAndThumbTip = Math.sqrt(
          (rightHandIndexFingerTipIndex[0] - rightHandThumbTipIndex[0]) ** 2 +
          (rightHandIndexFingerTipIndex[1] - rightHandThumbTipIndex[1]) ** 2 +
          (rightHandIndexFingerTipIndex[2] - rightHandThumbTipIndex[2]) ** 2
        );
        if (distanceBetweenrightHandIndexFingerTipAndThumbTip < 0.016) {

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

      gl.clearColor(0.0, 0.0, 0.0, 0.1);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

      for (const view of pose.views) {
        const viewport = xrGLLayer.getViewport(view);
        gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);

        gl.uniformMatrix4fv(projectionLocation, false, view.projectionMatrix);
        gl.uniformMatrix4fv(viewLocation, false, view.transform.inverse.matrix);
        gl.uniformMatrix4fv(modelLocation, false, new Float32Array(IDENTITY_MATRIX));

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

        // render the scene graphic data

        drawAllSceneObjects(gl, modelLocation, sceneObjects, sceneObjectsGraphicData)
      }

      xrSession.requestAnimationFrame(onXRFrame);
    }

    xrSession.requestAnimationFrame(onXRFrame);
  }
}

await main()
