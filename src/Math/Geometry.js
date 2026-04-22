export const rayTriangleIntersectImpl = (ray) => (v0) => (v1) => (v2) => {
  const EPSILON = 0.000001;

  const e1 = [v1[0] - v0[0], v1[1] - v0[1], v1[2] - v0[2]];
  const e2 = [v2[0] - v0[0], v2[1] - v0[1], v2[2] - v0[2]];

  const p = [
    ray.direction[1] * e2[2] - ray.direction[2] * e2[1],
    ray.direction[2] * e2[0] - ray.direction[0] * e2[2],
    ray.direction[0] * e2[1] - ray.direction[1] * e2[0]
  ];

  const det = e1[0] * p[0] + e1[1] * p[1] + e1[2] * p[2];
  if (det > -EPSILON && det < EPSILON) return null;

  const invDet = 1.0 / det;

  const t_vec = [
    ray.origin[0] - v0[0],
    ray.origin[1] - v0[1],
    ray.origin[2] - v0[2]
  ];

  const u = (t_vec[0] * p[0] + t_vec[1] * p[1] + t_vec[2] * p[2]) * invDet;
  if (u < 0.0 || u > 1.0) return null;

  const q = [
    t_vec[1] * e1[2] - t_vec[2] * e1[1],
    t_vec[2] * e1[0] - t_vec[0] * e1[2],
    t_vec[0] * e1[1] - t_vec[1] * e1[0]
  ];

  const v = (ray.direction[0] * q[0] + ray.direction[1] * q[1] + ray.direction[2] * q[2]) * invDet;
  if (v < 0.0 || u + v > 1.0) return null;

  const t = (e2[0] * q[0] + e2[1] * q[1] + e2[2] * q[2]) * invDet;

  if (t > EPSILON) return t;

  return null;
};
