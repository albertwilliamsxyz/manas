export const makeXRWebGL2CompatibleImpl = (gl) => () => gl.makeXRCompatible();

export const getXRSystem = (navigator) => () => navigator.xr == null ? null : navigator.xr;
export const isWebXRSessionModeSupportedImpl = (xr) => (mode) => () => xr.isSessionSupported(mode);

export const requestSessionImpl = (xr) => (mode) => (opts) => () => xr.requestSession(mode, opts);

export const createXRWebGLLayer = (window) => (xrSession) => (gl) => () => new window.XRWebGLLayer(xrSession, gl);

export const updateRenderState = (xrSession) => (options) => () => xrSession.updateRenderState(options);

