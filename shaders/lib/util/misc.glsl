#ifndef MISC_GLSL
#define MISC_GLSL

#include "/lib/util/jessie_utils.glsl"

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

vec2 vogel_disc_sample(int step_index, int step_count, float jitter) {
  float rotation = jitter * 2 * PI;
  const float golden_angle = 2.4;

  float r = sqrt(step_index + 0.5) / sqrt(float(step_count));
  float theta = step_index * golden_angle + rotation;

  return r * vec2(cos(theta), sin(theta));
}

#endif // MISC_GLSL
