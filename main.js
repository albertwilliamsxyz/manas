const numberOfJointsPerHand = 25;

const exampleLeftHand = [
  -0.1766360104084015, 0.07610338926315308, -0.015291444957256317,
  -0.20352071523666382, 0.10378003120422363, -0.04369589686393738,
  -0.2241339534521103, 0.12098053097724915, -0.06203514337539673,
  -0.24110397696495056, 0.1355462372303009, -0.08736954629421234,
  -0.25522714853286743, 0.14834152162075043, -0.10295887291431427,
  -0.1972396969795227, 0.0936996340751648, -0.047591496258974075,
  -0.21244263648986816, 0.09489300101995468, -0.10578055679798126,
  -0.2172755002975464, 0.11188487708568573, -0.13934245705604553,
  -0.21465106308460236, 0.1286224126815796, -0.1567675769329071,
  -0.20925717055797577, 0.14496412873268127, -0.17108935117721558,
  -0.1835198849439621, 0.08472517877817154, -0.048262640833854675,
  -0.19587740302085876, 0.080236054956913, -0.10894192010164261,
  -0.19438734650611877, 0.09303972125053406, -0.14988791942596436,
  -0.18883055448532104, 0.10880127549171448, -0.17178940773010254,
  -0.18239448964595795, 0.1253141164779663, -0.18941155076026917,
  -0.1678108125925064, 0.07458393275737762, -0.05257555842399597,
  -0.1761317253112793, 0.07445402443408966, -0.10590757429599762,
  -0.17105722427368164, 0.08025527000427246, -0.14413440227508545,
  -0.16384181380271912, 0.09652440249919891, -0.16386759281158447,
  -0.15741822123527527, 0.11639734357595444, -0.17644605040550232,
  -0.15918733179569244, 0.07372421771287918, -0.053613223135471344,
  -0.1555015593767166, 0.0721837505698204, -0.09908866137266159,
  -0.14538179337978363, 0.07109090685844421, -0.12807384133338928,
  -0.1370963752269745, 0.0834783986210823, -0.14187434315681458,
  -0.13212719559669495, 0.10228075087070465, -0.15206792950630188
]

const exampleRightHand = [
  0.14586004614830017, 0.0829494297504425, -0.15782345831394196,
  0.14336976408958435, 0.11027027666568756, -0.1977381706237793,
  0.1404651403427124, 0.13333238661289215, -0.22047123312950134,
  0.133914977312088, 0.1526736170053482, -0.2473967969417572,
  0.13123184442520142, 0.1695503294467926, -0.2651221454143524,
  0.13978393375873566, 0.09835579246282578, -0.1969263255596161,
  0.12170515209436417, 0.09167913347482681, -0.25355109572410583,
  0.10675258934497833, 0.0923023447394371, -0.28840094804763794,
  0.09154143929481506, 0.10001233965158463, -0.30571699142456055,
  0.0755542516708374, 0.10822688043117523, -0.31906574964523315,
  0.1309855878353119, 0.08662279695272446, -0.18948788940906525,
  0.11053264141082764, 0.07374674826860428, -0.24628253281116486,
  0.08746447414159775, 0.06809412688016891, -0.2820405662059784,
  0.06727784872055054, 0.07367419451475143, -0.29993870854377747,
  0.04806271940469742, 0.0817003846168518, -0.3137587904930115,
  0.11934724450111389, 0.07301866263151169, -0.18368364870548248,
  0.0977574810385704, 0.06486964970827103, -0.23247948288917542,
  0.06979886442422867, 0.0602673776447773, -0.25927186012268066,
  0.04823671281337738, 0.06549029052257538, -0.27389857172966003,
  0.029007762670516968, 0.07450494915246964, -0.2858734130859375,
  0.11207547038793564, 0.07031981647014618, -0.1796814352273941,
  0.0853574350476265, 0.0598897710442543, -0.21519669890403748,
  0.056272827088832855, 0.0613681860268116, -0.22497642040252686,
  0.03698127716779709, 0.06635294109582901, -0.22891861200332642,
  0.01668773591518402, 0.07140295207500458, -0.2356119155883789
]

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

const webGL2Version = '#version 300 es'

const vertexShaderSource = webGL2Version + `
in vec3 a_position;
uniform mat4 u_projection;
uniform mat4 u_view;
void main() {
  gl_Position = u_projection * u_view * vec4(a_position, 1.0);
  gl_PointSize = 15.0;
}
`

const fragmentShaderSource = webGL2Version + `
precision highp float;

out vec4 outColor;

void main() {
  outColor = vec4(0.2, 0.7, 0.2, 0.2);
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

  const isWebXRSupported = await navigator.xr.isSessionSupported('immersive-ar');
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

  const positionAttributeLocation = gl.getAttribLocation(program, 'a_position')

  // Declaration of resources for the main model

  const mainModelBuffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, mainModelBuffer)
  gl.bufferData(gl.ARRAY_BUFFER, cubeVertices, gl.STATIC_DRAW)
  const numberOfVerticesInMainModel = cubeVertices.length / numberOfDimensions

  const mainModelVAO = gl.createVertexArray()
  gl.bindVertexArray(mainModelVAO)

  gl.vertexAttribPointer(
    positionAttributeLocation,
    numberOfDimensions,
    gl.FLOAT,
    false,
    0,
    0
  )
  gl.enableVertexAttribArray(positionAttributeLocation)

  // Declaration of resources for the hand models

  // Left hand

  const leftHandBuffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, leftHandBuffer)
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(
    new Array(numberOfJointsPerHand * numberOfDimensions).fill(0)
  ), gl.DYNAMIC_DRAW)

  const leftHandVAO = gl.createVertexArray()
  gl.bindVertexArray(leftHandVAO)

  gl.vertexAttribPointer(
    positionAttributeLocation,
    numberOfDimensions,
    gl.FLOAT,
    false,
    0,
    0
  )
  gl.enableVertexAttribArray(positionAttributeLocation)

  // Right hand

  const rightHandBuffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, rightHandBuffer)
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(
    new Array(numberOfJointsPerHand * numberOfDimensions).fill(0)
  ), gl.DYNAMIC_DRAW)

  const rightHandVAO = gl.createVertexArray()
  gl.bindVertexArray(rightHandVAO)

  gl.vertexAttribPointer(
    positionAttributeLocation,
    numberOfDimensions,
    gl.FLOAT,
    false,
    0,
    0
  )
  gl.enableVertexAttribArray(positionAttributeLocation)

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

    const onXRFrame = (time, xrFrame) => {
      const leftHandVertices = new Array(numberOfJointsPerHand * numberOfDimensions).fill(0);
      const rightHandVertices = new Array(numberOfJointsPerHand * numberOfDimensions).fill(0);
      for (const inputSource of xrSession.inputSources) {
        if (!inputSource.hand) continue

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
        gl.drawArrays(gl.TRIANGLES, 0, numberOfVerticesInMainModel);

        gl.bindVertexArray(leftHandVAO);
        gl.drawArrays(gl.POINTS, 0, numberOfJointsPerHand);

        gl.bindVertexArray(rightHandVAO);
        gl.drawArrays(gl.POINTS, 0, numberOfJointsPerHand);
      }

      xrSession.requestAnimationFrame(onXRFrame);
    }

    xrSession.requestAnimationFrame(onXRFrame)
  };
}

await main()
