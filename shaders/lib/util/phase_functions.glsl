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

float dual_lobe_hg_phase(float cos_theta, float g0, float g1, float alpha) {
  return mix(
    henyey_greenstein_phase(cos_theta, g0),
    henyey_greenstein_phase(cos_theta, g1),
    alpha
  );
}

float draine_phase(float cos_theta, float g, float a) {
  return (1 - g * g) *
  (1 + a * cos_theta * cos_theta) /
  (4.0 *
    (1 + a * (1 + 2 * g * g) / 3.0) *
    PI *
    pow(1 + g * g - 2 * g * cos_theta, 1.5));
}

float hg_draine_phase(float cos_theta, const float d) {
  const float g_hg = exp(-0.0990567 / (d - 1.67154));
  const float g_d = exp(-2.20679 / (d + 3.91029) - 0.428934);
  const float a = exp(3.62489 - 8.29288 / (d + 5.52825));
  const float w = exp(-0.599085 / (d - 0.641583) - 0.665888);

  return mix(
    henyey_greenstein_phase(cos_theta, g_hg),
    draine_phase(cos_theta, g_d, a),
    w
  );
}

#endif // PHASE_FUNCTIONS_GLSL
