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

  float true_distance =
    blocker_distance * get_shadow_map_pixel_size(CASCADES - 1).z;

  vec3 scatter =
    albedo *
    sunlight_color *
    exp(
      -true_distance * rcp(albedo / max(0.1, sqrt(luminance(albedo)))) * 0.3
    ) *
    henyey_greenstein_phase(VoL, 0.3) *
    PI *
    2.0 *
    subsurface_scattering;

  if (any(isnan(scatter))) {
    scatter = vec3(0.0);
  }

  return scatter;

}

#endif
