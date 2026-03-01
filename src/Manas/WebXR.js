// FFI implementations for Manas.WebXR

export const getXRSystemImpl = function () {
  return navigator.xr || null;
};

export const isSessionSupported = function (xr) {
  return function (mode) {
    return function () {
      return xr.isSessionSupported(mode);
    };
  };
};

export const requestSession = function (xr) {
  return function (mode) {
    return function () {
      return xr.requestSession(mode, {
        optionalFeatures: ["hit-test", "hand-tracking"],
      });
    };
  };
};

export const createXRWebGLLayer = function (session) {
  return function (gl) {
    return function () {
      return new XRWebGLLayer(session, gl);
    };
  };
};

export const updateRenderState = function (session) {
  return function (layer) {
    return function () {
      session.updateRenderState({ baseLayer: layer });
    };
  };
};

export const requestReferenceSpace = function (session) {
  return function (type) {
    return function () {
      return session.requestReferenceSpace(type);
    };
  };
};

export const requestAnimationFrame = function (session) {
  return function (callback) {
    return function () {
      session.requestAnimationFrame(function (time, frame) {
        callback(time)(frame)();
      });
    };
  };
};

export const getInputSources = function (session) {
  return function () {
    return Array.from(session.inputSources);
  };
};

export const getHandImpl = function (inputSource) {
  return inputSource.hand || null;
};

export const getHandedness = function (inputSource) {
  return inputSource.handedness;
};

export const getHandEntries = function (hand) {
  return function () {
    var entries = [];
    for (var entry of hand) {
      entries.push({ jointName: entry[0], jointSpace: entry[1] });
    }
    return entries;
  };
};

export const getJointPoseImpl = function (frame) {
  return function (jointSpace) {
    return function (referenceSpace) {
      return function () {
        if (frame.getJointPose) {
          return frame.getJointPose(jointSpace, referenceSpace) || null;
        }
        return null;
      };
    };
  };
};

export const getJointPosePosition = function (jointPose) {
  return {
    x: jointPose.transform.position.x,
    y: jointPose.transform.position.y,
    z: jointPose.transform.position.z,
  };
};

export const getViewerPoseImpl = function (frame) {
  return function (referenceSpace) {
    return function () {
      return frame.getViewerPose(referenceSpace) || null;
    };
  };
};

export const getViews = function (pose) {
  return Array.from(pose.views);
};

export const getViewProjectionMatrix = function (view) {
  return Array.from(view.projectionMatrix);
};

export const getViewTransformInverseMatrix = function (view) {
  return Array.from(view.transform.inverse.matrix);
};

export const getViewportImpl = function (layer) {
  return function (view) {
    return layer.getViewport(view) || null;
  };
};

export const getViewportDimensions = function (vp) {
  return { x: vp.x, y: vp.y, width: vp.width, height: vp.height };
};

export const getFramebuffer = function (layer) {
  return layer.framebuffer;
};
