export const addImpl = (a) => (b) =>
  new Float32Array([a[0] + b[0], a[1] + b[1], a[2] + b[2]]);

export const subImpl = (a) => (b) =>
  new Float32Array([a[0] - b[0], a[1] - b[1], a[2] - b[2]]);

export const scaleImpl = (k) => (v) =>
  new Float32Array([k * v[0], k * v[1], k * v[2]]);

export const dotImpl = (a) => (b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

export const crossImpl = (a) => (b) =>
  new Float32Array([
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0]
  ]);
