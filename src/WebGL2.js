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
