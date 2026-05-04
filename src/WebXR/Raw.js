export const makeXRWebGL2Compatible = (gl) => () => gl.makeXRCompatible();

export const getXRSystem = (navigator) => () => navigator.xr == null ? null : navigator.xr;
export const isWebXRSessionModeSupported = (xr) => (mode) => () => xr.isSessionSupported(mode);

export const requestSession = (xr) => (mode) => (opts) => () => xr.requestSession(mode, opts);

export const createXRWebGLLayer = (window) => (xrSession) => (gl) => () => new window.XRWebGLLayer(xrSession, gl);

export const updateRenderState = (xrSession) => (options) => () => xrSession.updateRenderState(options);

export const requestReferenceSpace = (xrSession) => (type) => () => xrSession.requestReferenceSpace(type);

export const requestAnimationFrame = (session) => (callback) => () =>
  session.requestAnimationFrame((time, frame) => {
    callback(time)(frame)();
  });

export const getViewerPose = (frame) => (referenceSpace) => () =>
  frame.getViewerPose(referenceSpace) || null;

export const getViewerPosePosition = (pose) => () => {
  const p = pose.transform.position;
  return new Float32Array([p.x, p.y, p.z]);
};

export const getJointPose = (frame) => (jointSpace) => (referenceSpace) => () => {
  if (!frame.getJointPose) return null;
  return frame.getJointPose(jointSpace, referenceSpace) || null;
};

export const getInputSources = (session) => () =>
  (session && session.inputSources) ? Array.from(session.inputSources) : [];

export const getHand = (source) => () =>
  (source && source.hand) ? source.hand : null;

export const getHandedness = (source) => () =>
  (source && typeof source.handedness === "string") ? source.handedness : null;

export const getHandJoints = (hand) => () => Array.from(hand.entries()).map(([name, space]) => ({ name, space }));

export const getJointPosition = (pose) => () => new Float32Array([pose.transform.position.x, pose.transform.position.y, pose.transform.position.z]);

export const getViews = (pose) => () => Array.from(pose.views);

export const getViewport = (layer) => (view) => () => layer.getViewport(view);

export const getProjectionMatrix = (view) => () => new Float32Array(view.projectionMatrix);

export const getViewMatrix = (view) => () => new Float32Array(view.transform.inverse.matrix);

export const getFramebuffer = (layer) => () => layer.framebuffer;
