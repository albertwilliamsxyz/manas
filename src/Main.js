// FFI implementations for Main

var HAND_JOINT_INDICES_BY_NAME = {
  wrist: 0,
  "thumb-metacarpal": 1,
  "thumb-phalanx-proximal": 2,
  "thumb-phalanx-distal": 3,
  "thumb-tip": 4,
  "index-finger-metacarpal": 5,
  "index-finger-phalanx-proximal": 6,
  "index-finger-phalanx-intermediate": 7,
  "index-finger-phalanx-distal": 8,
  "index-finger-tip": 9,
  "middle-finger-metacarpal": 10,
  "middle-finger-phalanx-proximal": 11,
  "middle-finger-phalanx-intermediate": 12,
  "middle-finger-phalanx-distal": 13,
  "middle-finger-tip": 14,
  "ring-finger-metacarpal": 15,
  "ring-finger-phalanx-proximal": 16,
  "ring-finger-phalanx-intermediate": 17,
  "ring-finger-phalanx-distal": 18,
  "ring-finger-tip": 19,
  "pinky-finger-metacarpal": 20,
  "pinky-finger-phalanx-proximal": 21,
  "pinky-finger-phalanx-intermediate": 22,
  "pinky-finger-phalanx-distal": 23,
  "pinky-finger-tip": 24,
};

var HAND_SKELETON_BY_JOINT_INDICES = [
  0, 1, 1, 2, 2, 3, 3, 4, 0, 5, 5, 6, 6, 7, 7, 8, 8, 9, 0, 10, 10, 11, 11,
  12, 12, 13, 13, 14, 0, 15, 15, 16, 16, 17, 17, 18, 18, 19, 0, 20, 20, 21,
  21, 22, 22, 23, 23, 24,
];

var BASE_NUMBER_OF_DIMENSIONS = 3;
var NUMBER_OF_JOINTS_PER_HAND = 25;
var NUMBER_OF_HAND_JOINT_DIMENSIONS =
  NUMBER_OF_JOINTS_PER_HAND * BASE_NUMBER_OF_DIMENSIONS;

export const distanceImpl = function (arr) {
  return function (idx1) {
    return function (idx2) {
      if (
        !arr ||
        arr.length < idx1 + 3 ||
        arr.length < idx2 + 3
      ) {
        return Infinity;
      }
      var dx = arr[idx1] - arr[idx2];
      var dy = arr[idx1 + 1] - arr[idx2 + 1];
      var dz = arr[idx1 + 2] - arr[idx2 + 2];
      return Math.sqrt(dx * dx + dy * dy + dz * dz);
    };
  };
};

export const processHandInputImpl = function (frame) {
  return function (refSpace) {
    return function (sources) {
      return function () {
        var leftVertices = new Array(NUMBER_OF_HAND_JOINT_DIMENSIONS).fill(0);
        var rightVertices = new Array(NUMBER_OF_HAND_JOINT_DIMENSIONS).fill(0);

        for (var i = 0; i < sources.length; i++) {
          var inputSource = sources[i];
          if (!inputSource.hand) continue;

          var isLeft = inputSource.handedness === "left";
          var verticesRef = isLeft ? leftVertices : rightVertices;

          for (var entry of inputSource.hand) {
            var jointName = entry[0];
            var jointSpace = entry[1];
            var jointPose = frame.getJointPose
              ? frame.getJointPose(jointSpace, refSpace)
              : null;
            if (!jointPose) continue;

            var idx = HAND_JOINT_INDICES_BY_NAME[jointName];
            if (idx === undefined) continue;

            verticesRef[idx * 3] = jointPose.transform.position.x;
            verticesRef[idx * 3 + 1] = jointPose.transform.position.y;
            verticesRef[idx * 3 + 2] = jointPose.transform.position.z;
          }
        }

        return { leftVertices: leftVertices, rightVertices: rightVertices };
      };
    };
  };
};

export const renderViewsImpl = function (gl) {
  return function (uniforms) {
    return function (xrLayer) {
      return function (vaos) {
        return function (views) {
          return function () {
            for (var i = 0; i < views.length; i++) {
              var view = views[i];
              var vp = xrLayer.getViewport(view);
              if (!vp) continue;

              gl.viewport(vp.x, vp.y, vp.width, vp.height);

              gl.uniformMatrix4fv(
                uniforms.projection,
                false,
                view.projectionMatrix
              );
              gl.uniformMatrix4fv(
                uniforms.view,
                false,
                view.transform.inverse.matrix
              );
              gl.uniformMatrix4fv(
                uniforms.model,
                false,
                new Float32Array([
                  1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1,
                ])
              );

              // Draw left hand joints
              gl.bindVertexArray(vaos.leftHandVAO);
              gl.drawArrays(gl.POINTS, 0, NUMBER_OF_JOINTS_PER_HAND);

              // Draw left hand skeleton
              gl.bindVertexArray(vaos.leftSkeletonVAO);
              gl.drawElements(
                gl.LINES,
                HAND_SKELETON_BY_JOINT_INDICES.length,
                gl.UNSIGNED_SHORT,
                0
              );

              // Draw right hand joints
              gl.bindVertexArray(vaos.rightHandVAO);
              gl.drawArrays(gl.POINTS, 0, NUMBER_OF_JOINTS_PER_HAND);

              // Draw right hand skeleton
              gl.bindVertexArray(vaos.rightSkeletonVAO);
              gl.drawElements(
                gl.LINES,
                HAND_SKELETON_BY_JOINT_INDICES.length,
                gl.UNSIGNED_SHORT,
                0
              );

              // Draw cube
              gl.bindVertexArray(vaos.cubeVAO);
              gl.drawArrays(gl.POINTS, 0, 36); // 108 / 3
            }
          };
        };
      };
    };
  };
};

export const setupStartButton = function (buttonId) {
  return function (callback) {
    return function () {
      var button = document.getElementById(buttonId);
      if (button) {
        button.onclick = function () {
          callback();
        };
      } else {
        console.error("Start experience button not found");
      }
    };
  };
};
