export const float32Array = (arr) => new Float32Array(arr);
export const uint16Array = (arr) => new Uint16Array(arr);

export const getAt = (arr) => (i) => () => arr[i];
export const setAt = (arr) => (i) => (val) => () => { arr[i] = val; };

export const copyInto = (target) => (source) => (offset) => () => target.set(source, offset);
export const subarray = (array) => (start) => (end) => () => array.subarray(start, end);

export const toArray = (typedArray) => Array.from(typedArray);
