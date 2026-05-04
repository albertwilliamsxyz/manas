export const getContext = (canvas) => () => canvas.getContext('webgl2');

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
export const uniform1i = (gl) => (location) => (value) => () => gl.uniform1i(location, value);
export const uniform1f = (gl) => (location) => (value) => () => gl.uniform1f(location, value);
export const uniform3fv = (gl) => (location) => (value) => () => gl.uniform3fv(location, value);
export const uniform1fv = (gl) => (location) => (value) => () => gl.uniform1fv(location, value);

export const createVertexArray = (gl) => () => gl.createVertexArray();
export const bindVertexArray = (gl) => (vao) => () => gl.bindVertexArray(vao);
export const createBuffer = (gl) => () => gl.createBuffer();
export const bindBuffer = (gl) => (target) => (buffer) => () => gl.bindBuffer(target, buffer);
export const bufferData = (gl) => (target) => (data) => (usage) => () => gl.bufferData(target, data, usage);
export const vertexAttribPointer = (gl) => (index) => (size) => (type) => (normalized) => (stride) => (offset) => () => gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
export const enableVertexAttribArray = (gl) => (index) => () => gl.enableVertexAttribArray(index);

export const enable = (gl) => (capability) => () => gl.enable(capability);
export const disable = (gl) => (capability) => () => gl.disable(capability);
export const blendFunc = (gl) => (sfactor) => (dfactor) => () => gl.blendFunc(sfactor, dfactor);

export const bufferSubData = (gl) => (target) => (offset) => (data) => () => gl.bufferSubData(target, offset, data);

export const bindFramebuffer = (gl) => (target) => (framebuffer) => () => gl.bindFramebuffer(target, framebuffer);

export const createFramebuffer = (gl) => () => gl.createFramebuffer();
export const framebufferTexture2D = (gl) => (target) => (attachment) => (textarget) => (texture) => (level) => () => gl.framebufferTexture2D(target, attachment, textarget, texture, level);
export const checkFramebufferStatus = (gl) => (target) => () => gl.checkFramebufferStatus(target);

export const clearColor = (gl) => (r) => (g) => (b) => (a) => () => gl.clearColor(r, g, b, a);

export const clear = (gl) => (mask) => () => gl.clear(mask);

export const viewport = (gl) => (x) => (y) => (w) => (h) => () => gl.viewport(x, y, w, h);

export const drawArrays = (gl) => (mode) => (first) => (count) => () => gl.drawArrays(mode, first, count);

export const drawElements = (gl) => (mode) => (count) => (type) => (offset) => () => gl.drawElements(mode, count, type, offset);

export const createTexture = (gl) => () => gl.createTexture();
export const bindTexture = (gl) => (target) => (texture) => () => gl.bindTexture(target, texture);
export const texImage2D = (gl) => (target) => (level) => (internalFormat) => (width) => (height) => (border) => (format) => (type) => (data) => () => gl.texImage2D(target, level, internalFormat, width, height, border, format, type, data);
export const texImage2DFromImage = (gl) => (target) => (level) => (internalFormat) => (format) => (type) => (image) => () => gl.texImage2D(target, level, internalFormat, format, type, image);
export const texParameteri = (gl) => (target) => (pname) => (param) => () => gl.texParameteri(target, pname, param);
export const generateMipmap = (gl) => (target) => () => gl.generateMipmap(target);
export const activeTexture = (gl) => (texture) => () => gl.activeTexture(texture);
