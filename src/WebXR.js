export const makeXRWebGL2CompatibleImpl = (gl) => () => gl.makeXRCompatible();

export const getXRSystem = (navigator) => () => navigator.xr == null ? null : navigator.xr;
export const isWebXRSessionModeSupportedImpl = (xr) => (mode) => () => xr.isSessionSupported(mode);

export const requestSessionImpl = (xr) => (mode) => (opts) => () => xr.requestSession(mode, opts);

export const createXRWebGLLayer = (window) => (xrSession) => (gl) => () => new window.XRWebGLLayer(xrSession, gl);

export const updateRenderState = (xrSession) => (options) => () => xrSession.updateRenderState(options);

export const requestReferenceSpaceImpl = (xrSession) => (type) => () => xrSession.requestReferenceSpace(type);

export const requestAnimationFrame = (session) => (callback) => () =>
  session.requestAnimationFrame((time, frame) => {
    callback(time)(frame)();
  });

export const getViewerPose = (frame) => (referenceSpace) => () =>
  frame.getViewerPose(referenceSpace) || null;

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

export const getHandJoints = (hand) => () => Array.from(hand.entries());

export const getJointPosition = (pose) => () => new Float32Array([pose.transform.position.x, pose.transform.position.y, pose.transform.position.z]);

export const getViews = (pose) => () => Array.from(pose.views);

export const getViewport = (layer) => (view) => () => layer.getViewport(view);

export const getProjectionMatrix = (view) => () => new Float32Array(view.projectionMatrix);

export const getViewMatrix = (view) => () => new Float32Array(view.transform.inverse.matrix);


export const getFramebuffer = (layer) => () => layer.framebuffer;

