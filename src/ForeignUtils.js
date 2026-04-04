export const float32Array = (arr) => new Float32Array(arr);
export const uint16Array = (arr) => new Uint16Array(arr);

export const getAt = (arr) => (i) => () => arr[i];
export const setAt = (arr) => (i) => (val) => () => { arr[i] = val; };

export const copyInto = (target) => (source) => (offset) => () => target.set(source, offset);

export const subarray = (array) => (start) => (end) => () => array.subarray(start, end);

export const get3DDistance = (arrayA) => (arrayB) => () => Math.sqrt((arrayA[0] - arrayB[0]) ** 2 + (arrayA[1] - arrayB[1]) ** 2 + (arrayA[2] - arrayB[2]) ** 2);

export const get3DDistanceFromMatrix = (point) => (matrix) =>
  Math.sqrt(
    (point[0] - matrix[12]) ** 2 +
    (point[1] - matrix[13]) ** 2 +
    (point[2] - matrix[14]) ** 2
  );

export const toArray = (typedArray) => Array.from(typedArray);

export const multiplyMatrix4x4 = (a) => (b) => {
  const out = new Float32Array(16);
  for (let i = 0; i < 4; i++) {
    for (let j = 0; j < 4; j++) {
      out[j * 4 + i] =
        a[i] * b[j * 4] +
        a[4 + i] * b[j * 4 + 1] +
        a[8 + i] * b[j * 4 + 2] +
        a[12 + i] * b[j * 4 + 3];
    }
  }
  return out;
};

export const dot3 = (a) => (b) =>
  a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

export const cross3 = (a) => (b) =>
  new Float32Array([
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0]
  ]);

export const sub3 = (a) => (b) =>
  new Float32Array([
    a[0] - b[0], a[1] - b[1], a[2] - b[2]
  ]);

export const normalize3 = (v) => {
  const len = Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
  if (len === 0) return new Float32Array([0, 0, 0]);
  return new Float32Array([v[0] / len, v[1] / len, v[2] / len]);
};

export const rayTriangleIntersect = (ray) => (v0) => (v1) => (v2) => {
  const EPSILON = 0.000001;

  // Paso 1: dos edges del triángulo desde V0
  const e1 = [v1[0] - v0[0], v1[1] - v0[1], v1[2] - v0[2]];
  const e2 = [v2[0] - v0[0], v2[1] - v0[1], v2[2] - v0[2]];

  // Paso 2: P = direction × E2
  const p = [
    ray.direction[1] * e2[2] - ray.direction[2] * e2[1],
    ray.direction[2] * e2[0] - ray.direction[0] * e2[2],
    ray.direction[0] * e2[1] - ray.direction[1] * e2[0]
  ];

  // Paso 3: determinante = E1 · P
  // Si ~0, el rayo es paralelo al triángulo
  const det = e1[0] * p[0] + e1[1] * p[1] + e1[2] * p[2];
  if (det > -EPSILON && det < EPSILON) return null;

  const invDet = 1.0 / det;

  // Paso 4: T = origin - V0
  const t_vec = [
    ray.origin[0] - v0[0],
    ray.origin[1] - v0[1],
    ray.origin[2] - v0[2]
  ];

  // Paso 5: u = (T · P) / det
  const u = (t_vec[0] * p[0] + t_vec[1] * p[1] + t_vec[2] * p[2]) * invDet;
  if (u < 0.0 || u > 1.0) return null;

  // Paso 6: Q = T × E1
  const q = [
    t_vec[1] * e1[2] - t_vec[2] * e1[1],
    t_vec[2] * e1[0] - t_vec[0] * e1[2],
    t_vec[0] * e1[1] - t_vec[1] * e1[0]
  ];

  // Paso 7: v = (direction · Q) / det
  const v = (ray.direction[0] * q[0] + ray.direction[1] * q[1] + ray.direction[2] * q[2]) * invDet;
  if (v < 0.0 || u + v > 1.0) return null;

  // Paso 8: t = (E2 · Q) / det
  const t = (e2[0] * q[0] + e2[1] * q[1] + e2[2] * q[2]) * invDet;

  // t > EPSILON significa que la intersección está delante del rayo, no detrás
  if (t > EPSILON) return t;

  return null;
};

export const transformPoint3 = (matrix) => (point) => {
  const x = point[0], y = point[1], z = point[2];
  return new Float32Array([
    matrix[0] * x + matrix[4] * y + matrix[8] * z + matrix[12],
    matrix[1] * x + matrix[5] * y + matrix[9] * z + matrix[13],
    matrix[2] * x + matrix[6] * y + matrix[10] * z + matrix[14]
  ]);
};

export const translationMatrix4x4 = (v) => new Float32Array([
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  v[0], v[1], v[2], 1
]);

export const getTranslationFromMatrix = (matrix) =>
  new Float32Array([matrix[12], matrix[13], matrix[14]]);

export const midpoint3 = (a) => (b) => new Float32Array([
  (a[0] + b[0]) / 2,
  (a[1] + b[1]) / 2,
  (a[2] + b[2]) / 2
]);

export const add3 = (a) => (b) => new Float32Array([
  a[0] + b[0], a[1] + b[1], a[2] + b[2]
]);

export const getScaleFromMatrix = (matrix) => {
  const sx = Math.sqrt(matrix[0] * matrix[0] + matrix[1] * matrix[1] + matrix[2] * matrix[2]);
  return sx;
};

export const axisAngleRotationMatrix = (axis) => (cosAngle) => (sinAngle) => {
  const x = axis[0], y = axis[1], z = axis[2];
  const c = cosAngle, s = sinAngle, t = 1 - c;
  return new Float32Array([
    t * x * x + c, t * x * y + s * z, t * x * z - s * y, 0,
    t * x * y - s * z, t * y * y + c, t * y * z + s * x, 0,
    t * x * z + s * y, t * y * z - s * x, t * z * z + c, 0,
    0, 0, 0, 1
  ]);
};
