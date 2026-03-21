export const float32Array = (arr) => new Float32Array(arr);
export const uint16Array = (arr) => new Uint16Array(arr);


export const createContext = (canvas) => () => canvas.getContext('webgl2');

export const createShader = (gl) => (type) => () => gl.createShader(type);
export const shaderSource = (gl) => (shader) => (source) => () => gl.shaderSource(shader, source);
export const compileShader = (gl) => (shader) => () => gl.compileShader(shader);
export const getShaderParameter = (gl) => (shader) => (param) => () => gl.getShaderParameter(shader, param);
export const getShaderInfoLog = (gl) => (shader) => () => gl.getShaderInfoLog(shader);
export const deleteShader = (gl) => (shader) => () => gl.deleteShader(shader);

export const createProgram = (gl) => () => gl.createProgram();
export const attachShader = (gl) => (program) => (shader) => () => gl.attachShader(program, shader);
export const linkProgram = (gl) => (program) => () => gl.linkProgram(program);
export const useProgram = (gl) => (program) => () => gl.useProgram(program);
export const getProgramParameter = (gl) => (program) => (param) => () => gl.getProgramParameter(program, param);
export const getProgramInfoLog = (gl) => (program) => () => gl.getProgramInfoLog(program);
export const deleteProgram = (gl) => (program) => () => gl.deleteProgram(program);

export const getAttribLocation = (gl) => (program) => (name) => () => gl.getAttribLocation(program, name);

export const getUniformLocation = (gl) => (program) => (name) => () => gl.getUniformLocation(program, name);
export const uniformMatrix4fv = (gl) => (location) => (transpose) => (value) => () => gl.uniformMatrix4fv(location, transpose, value);
export const uniform4fv = (gl) => (location) => (value) => () => gl.uniform4fv(location, value);

export const createVertexArray = (gl) => () => gl.createVertexArray();
export const bindVertexArray = (gl) => (vao) => () => gl.bindVertexArray(vao);
export const createBuffer = (gl) => () => gl.createBuffer();
export const bindBuffer = (gl) => (target) => (buffer) => () => gl.bindBuffer(target, buffer);
export const bufferData = (gl) => (target) => (data) => (usage) => () => gl.bufferData(target, data, usage);
export const vertexAttribPointer = (gl) => (index) => (size) => (type) => (normalized) => (stride) => (offset) => () => gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
export const enableVertexAttribArray = (gl) => (index) => () => gl.enableVertexAttribArray(index);

export const enable = (gl) => (cap) => () => gl.enable(cap);

