export const float32Array = (arr) => new Float32Array(arr);
export const uint16Array = (arr) => new Uint16Array(arr);

export const getAt = (arr) => (i) => () => arr[i];
export const setAt = (arr) => (i) => (val) => () => { arr[i] = val; };

export const copyInto = (target) => (source) => (offset) => () => target.set(source, offset);

export const subarray = (array) => (start) => (end) => () => array.subarray(start, end);

export const get3DDistance = (arrayA) => (arrayB) => () => Math.sqrt((arrayA[0] - arrayB[0]) ** 2 + (arrayA[1] - arrayB[1]) ** 2 + (arrayA[2] - arrayB[2]) ** 2);

