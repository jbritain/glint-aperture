#ifndef PHASE_FUNCTIONS_GLSL
#define PHASE_FUNCTIONS_GLSL

float rayleigh_phase(float cos_theta) {
  return 3.0 * (1.0 + pow2(cos_theta)) / 16.0 * PI;
}

float cornette_shanks_phase(float cos_theta, float g) {
  return 3.0 /
  (8.0 * PI) *
  ((1.0 - pow2(g)) * (1.0 + pow2(cos_theta))) /
  ((2.0 + pow2(g)) * pow(1.0 + pow2(g) - 2.0 * g * cos_theta, 3.0 / 2.0));
}

float mie_phase(float cos_theta) {
  return cornette_shanks_phase(cos_theta, 0.8);
}

float henyey_greenstein_phase(float cos_theta, float g) {
  return (1.0 - g * g) /
  (4.0 * PI * pow(1.0 + g * g - 2.0 * g * cos_theta, 3.0 / 2.0));
}

#endif // PHASE_FUNCTIONS_GLSL
