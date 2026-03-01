// FFI implementations for Manas.Graphics

export const vertexShaderType = 0x8B31; // gl.VERTEX_SHADER
export const fragmentShaderType = 0x8B30; // gl.FRAGMENT_SHADER

export const getWebGL2ContextImpl = function (canvasId) {
  return function () {
    var canvas = document.getElementById(canvasId);
    if (!canvas) return null;
    return canvas.getContext("webgl2");
  };
};

export const createShaderImpl = function (gl) {
  return function (type) {
    return function () {
      return gl.createShader(type);
    };
  };
};

export const shaderSource = function (gl) {
  return function (shader) {
    return function (source) {
      return function () {
        gl.shaderSource(shader, source);
      };
    };
  };
};

export const compileShader = function (gl) {
  return function (shader) {
    return function () {
      gl.compileShader(shader);
    };
  };
};

export const getShaderParameter = function (gl) {
  return function (shader) {
    return function () {
      return !!gl.getShaderParameter(shader, gl.COMPILE_STATUS);
    };
  };
};

export const getShaderInfoLog = function (gl) {
  return function (shader) {
    return function () {
      return gl.getShaderInfoLog(shader) || "Unknown error";
    };
  };
};

export const deleteShader = function (gl) {
  return function (shader) {
    return function () {
      gl.deleteShader(shader);
    };
  };
};

export const createProgramImpl = function (gl) {
  return function () {
    return gl.createProgram();
  };
};

export const attachShader = function (gl) {
  return function (program) {
    return function (shader) {
      return function () {
        gl.attachShader(program, shader);
      };
    };
  };
};

export const linkProgram = function (gl) {
  return function (program) {
    return function () {
      gl.linkProgram(program);
    };
  };
};

export const getProgramParameter = function (gl) {
  return function (program) {
    return function () {
      return !!gl.getProgramParameter(program, gl.LINK_STATUS);
    };
  };
};

export const getProgramInfoLog = function (gl) {
  return function (program) {
    return function () {
      return gl.getProgramInfoLog(program) || "Unknown error";
    };
  };
};

export const deleteProgram = function (gl) {
  return function (program) {
    return function () {
      gl.deleteProgram(program);
    };
  };
};

export const useProgram = function (gl) {
  return function (program) {
    return function () {
      gl.useProgram(program);
    };
  };
};

export const getAttribLocation = function (gl) {
  return function (program) {
    return function (name) {
      return function () {
        return gl.getAttribLocation(program, name);
      };
    };
  };
};

export const getUniformLocationImpl = function (gl) {
  return function (program) {
    return function (name) {
      return function () {
        return gl.getUniformLocation(program, name);
      };
    };
  };
};

export const enableDepthTest = function (gl) {
  return function () {
    gl.enable(gl.DEPTH_TEST);
  };
};

export const createVertexArray = function (gl) {
  return function () {
    return gl.createVertexArray();
  };
};

export const bindVertexArray = function (gl) {
  return function (vao) {
    return function () {
      gl.bindVertexArray(vao);
    };
  };
};

export const createBuffer = function (gl) {
  return function () {
    return gl.createBuffer();
  };
};

export const bindArrayBuffer = function (gl) {
  return function (buffer) {
    return function () {
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    };
  };
};

export const bindElementArrayBuffer = function (gl) {
  return function (buffer) {
    return function () {
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, buffer);
    };
  };
};

export const bufferDataStaticDraw = function (gl) {
  return function (data) {
    return function () {
      gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(data), gl.STATIC_DRAW);
    };
  };
};

export const bufferDataDynamicDraw = function (gl) {
  return function (size) {
    return function () {
      gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(size), gl.DYNAMIC_DRAW);
    };
  };
};

export const bufferDataElementStaticDraw = function (gl) {
  return function (data) {
    return function () {
      gl.bufferData(
        gl.ELEMENT_ARRAY_BUFFER,
        new Uint16Array(data),
        gl.STATIC_DRAW
      );
    };
  };
};

export const bufferSubData = function (gl) {
  return function (data) {
    return function () {
      var arr = new Float32Array(data);
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, arr, 0, arr.length);
    };
  };
};

export const vertexAttribPointer = function (gl) {
  return function (location) {
    return function (size) {
      return function () {
        gl.vertexAttribPointer(location, size, gl.FLOAT, false, 0, 0);
      };
    };
  };
};

export const enableVertexAttribArray = function (gl) {
  return function (location) {
    return function () {
      gl.enableVertexAttribArray(location);
    };
  };
};

export const uniformMatrix4fv = function (gl) {
  return function (location) {
    return function (data) {
      return function () {
        gl.uniformMatrix4fv(location, false, new Float32Array(data));
      };
    };
  };
};

export const uniform4fv = function (gl) {
  return function (location) {
    return function (data) {
      return function () {
        gl.uniform4fv(location, new Float32Array(data));
      };
    };
  };
};

export const clearColor = function (gl) {
  return function (r) {
    return function (g) {
      return function (b) {
        return function (a) {
          return function () {
            gl.clearColor(r, g, b, a);
          };
        };
      };
    };
  };
};

export const clear = function (gl) {
  return function () {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  };
};

export const viewport = function (gl) {
  return function (x) {
    return function (y) {
      return function (w) {
        return function (h) {
          return function () {
            gl.viewport(x, y, w, h);
          };
        };
      };
    };
  };
};

export const drawArraysPoints = function (gl) {
  return function (first) {
    return function (count) {
      return function () {
        gl.drawArrays(gl.POINTS, first, count);
      };
    };
  };
};

export const drawArraysLineLoop = function (gl) {
  return function (first) {
    return function (count) {
      return function () {
        gl.drawArrays(gl.LINE_LOOP, first, count);
      };
    };
  };
};

export const drawElementsLines = function (gl) {
  return function (count) {
    return function () {
      gl.drawElements(gl.LINES, count, gl.UNSIGNED_SHORT, 0);
    };
  };
};

export const bindFramebuffer = function (gl) {
  return function (fb) {
    return function () {
      gl.bindFramebuffer(gl.FRAMEBUFFER, fb);
    };
  };
};

export const makeXRCompatible = function (gl) {
  return function () {
    return gl.makeXRCompatible();
  };
};
