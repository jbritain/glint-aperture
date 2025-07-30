#ifndef SUBSURFACE_SCATTERING_GLSL
#define SUBSURFACE_SCATTERING_GLSL

#include "/lib/util/shadow_space.glsl"
#include "/lib/util/phase_functions.glsl"

vec3 compute_subsurface_scattering(
  vec3 albedo,
  float subsurface_scattering,
  float blocker_distance,
  vec3 V,
  vec3 L
) {
  float VoL = saturate(dot(V, L));

  float true_distance = blocker_distance;
  return albedo *
  sunlight_color *
  PI *
  exp(-true_distance * 200.0) *
  max0(henyey_greenstein_phase(VoL, 0.3)) *
  subsurface_scattering;

}

#endif
