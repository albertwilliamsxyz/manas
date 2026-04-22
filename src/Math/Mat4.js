export const multiplyImpl = (a) => (b) => {
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

export const translationImpl = (v) => new Float32Array([
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  v[0], v[1], v[2], 1
]);

export const translationOfImpl = (m) =>
  new Float32Array([m[12], m[13], m[14]]);

export const scaleOfImpl = (m) =>
  Math.sqrt(m[0] * m[0] + m[1] * m[1] + m[2] * m[2]);

export const axisAngleRotationImpl = (axis) => (cosAngle) => (sinAngle) => {
  const x = axis[0], y = axis[1], z = axis[2];
  const c = cosAngle, s = sinAngle, t = 1 - c;
  return new Float32Array([
    t * x * x + c,     t * x * y + s * z, t * x * z - s * y, 0,
    t * x * y - s * z, t * y * y + c,     t * y * z + s * x, 0,
    t * x * z + s * y, t * y * z - s * x, t * z * z + c,     0,
    0,                 0,                 0,                 1
  ]);
};

export const transformPointImpl = (m) => (p) => {
  const x = p[0], y = p[1], z = p[2];
  return new Float32Array([
    m[0] * x + m[4] * y + m[8]  * z + m[12],
    m[1] * x + m[5] * y + m[9]  * z + m[13],
    m[2] * x + m[6] * y + m[10] * z + m[14]
  ]);
};
