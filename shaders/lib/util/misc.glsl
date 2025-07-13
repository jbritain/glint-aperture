#ifndef MISC_GLSL
#define MISC_GLSL

vec3 spherical_to_cartesian(vec2 coord) {
  float sin_theta = sin(coord.x);

  return vec3(
    sin(coord.y) * sin_theta,
    cos(coord.y),
    sin(coord.y) * cos(coord.x)
  );
}

vec2 cartesian_to_spherical(vec3 dir) {
  vec2 coord;
  coord.x = atan(dir.x, dir.z);
  coord.y = acos(dir.y);

  return coord;
}

// https://backend.orbit.dtu.dk/ws/portalfiles/portal/126824972/onb_frisvad_jgt2012_v2.pdf
mat3 generate_tbn(vec3 n) {
  mat3 tbn;
  tbn[2] = n;
  if (n.z < -0.9) {
    tbn[0] = vec3(0.0, -1, 0);
    tbn[1] = vec3(-1, 0, 0);
  } else {
    float a = 1.0 / (1.0 + n.z);
    float b = -n.x * n.y * a;
    tbn[0] = vec3(1.0 - n.x * n.x * a, b, -n.x);
    tbn[1] = vec3(b, 1.0 - n.y * n.y * a, -n.y);
  }
  return tbn;
}

// ===================>
// https://github.com/Jessie-LC/open-source-utility-code/blob/main/simple/misc.glsl

vec2 sincos(float x) {
  return vec2(sin(x), cos(x));
}

vec3 rotate(vec3 vector, vec3 axis, float angle) {
  // https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
  vec2 sc = sincos(angle);
  return sc.y * vector +
  sc.x * cross(axis, vector) +
  (1.0 - sc.y) * dot(axis, vector) * axis;
}

vec3 rotate(vec3 vector, vec3 from, vec3 to) {
  // where "from" and "to" are two unit vectors determining how far to rotate
  // adapted version of https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula

  float cosTheta = dot(from, to);
  if (abs(cosTheta) >= 0.9999) {
    return cosTheta < 0.0
      ? -vector
      : vector;
  }
  vec3 axis = normalize(cross(from, to));

  vec2 sc = vec2(sqrt(1.0 - cosTheta * cosTheta), cosTheta);
  return sc.y * vector +
  sc.x * cross(axis, vector) +
  (1.0 - sc.y) * dot(axis, vector) * axis;
}

// <==================

#endif // MISC_GLSL
