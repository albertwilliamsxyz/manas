export const float32Array = (arr) => new Float32Array(arr);
export const uint16Array = (arr) => new Uint16Array(arr);

export const getAt = (arr) => (i) => () => arr[i];
export const setAt = (arr) => (i) => (val) => () => { arr[i] = val; };

export const copyInto = (target) => (source) => (offset) => () => target.set(source, offset);

export const get3DDistance = (a) => (b) => () => Math.sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2);
