#ifndef MISC_GLSL
#define MISC_GLSL

vec3 spherical_to_cartesian(float theta, float phi) {
  float sin_theta = sin(theta);

  return vec3(sin(phi) * sin_theta, cos(phi), sin(phi) * cos(theta));
}

#endif // MISC_GLSL
