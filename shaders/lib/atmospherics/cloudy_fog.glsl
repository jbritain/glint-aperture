#ifndef CLOUDY_FOG_GLSL
#define CLOUDY_FOG_GLSL

#include "/lib/common.glsl"
#include "/lib/util/shadow_space.glsl"
#include "/lib/util/phase_functions.glsl"
#include "/lib/buffers/scene_data.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/misc.glsl"

#define VOLUMETRIC_FOG_STEPS 16

#define VOLUMETRIC_FOG_BOTTOM_PLANE 50
#define VOLUMETRIC_FOG_CENTRE_PLANE 63
#define VOLUMETRIC_FOG_TOP_PLANE 100

float cloudy_fog_density(vec3 pos) {
  return pos.y <= VOLUMETRIC_FOG_CENTRE_PLANE
    ? linearstep(
      VOLUMETRIC_FOG_BOTTOM_PLANE,
      VOLUMETRIC_FOG_CENTRE_PLANE,
      pos.y
    )
    : 1.0 -
      smoothstep(VOLUMETRIC_FOG_CENTRE_PLANE, VOLUMETRIC_FOG_TOP_PLANE, pos.y);
}

Volume water_fog(vec3 start_pos, vec3 end_pos) {
  vec3 ray_step = (end_pos - start_pos) / WATER_FOG_STEPS;
  float step_length = length(ray_step);
  vec3 ray_pos = start_pos;

  vec3 transmittance = vec3(1.0);
  vec3 scattering = vec3(0.0);

  ray_pos += blue_noise(floor(gl_FragCoord.xy), ap.time.frames).r * ray_step;

  vec3 step_transmittance = max0(exp(-length(ray_step) * water_extinction));

  float phase = rayleigh_phase(-dot(normalize(ray_step), world_light_dir));
  phase = multiple_scattering_water(phase, step_length);

  vec3 skylight_color =
    texture(
      sky_irradiance_lut_tex,
      cartesian_to_spherical(vec3(0.0, 1.0, 0.0)) / TAU
    ).rgb *
    isotropic_phase;

  for (int i = 0; i < WATER_FOG_STEPS; i++, ray_pos += ray_step) {
    int cascade;
    vec3 shadow_sample_pos = get_shadow_screen_pos(ray_pos, cascade);
    vec3 shadow_map_pixel_size = get_shadow_map_pixel_size(cascade);

    vec3 transmittance_to_sun = vec3(
      texture(
        solidShadowMapFiltered,
        vec4(shadow_sample_pos.xy, cascade, shadow_sample_pos.z)
      ).r
    );
    if (min_vec3(transmittance_to_sun) > 0.01) {
      float translucent_shadow_depth = texture(
        shadowMap,
        vec3(shadow_sample_pos.xy, cascade)
      ).r;

      float blocker_distance =
        (shadow_sample_pos.z - translucent_shadow_depth) *
        shadow_map_pixel_size.z;

      transmittance_to_sun *= exp(-blocker_distance * water_extinction);

    }
    vec3 radiance =
      sunlight_color * phase * transmittance_to_sun +
      skylight_color * isotropic_phase;
    scattering +=
      transmittance *
      (radiance * (1.0 - step_transmittance)) *
      water_scattering_albedo;
    transmittance *= step_transmittance;
  }

  mat2x3 water_fog;

  return Volume(transmittance, scattering);
}

#endif // CLOUDY_FOG_GLSL
