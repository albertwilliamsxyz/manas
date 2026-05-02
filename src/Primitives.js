export const float32Array = (arr) => new Float32Array(arr);
export const uint16Array = (arr) => new Uint16Array(arr);
export const uint8Array = (arr) => new Uint8Array(arr);

export const f32AsArrayBufferView = (x) => x;
export const u16AsArrayBufferView = (x) => x;
export const u8AsArrayBufferView = (x) => x;

export const getAt = (arr) => (i) => () => arr[i];
export const setAt = (arr) => (i) => (val) => () => { arr[i] = val; };

export const copyInto = (target) => (source) => (offset) => () => target.set(source, offset);
export const subarray = (array) => (start) => (end) => () => array.subarray(start, end);

export const toArray = (typedArray) => Array.from(typedArray);
