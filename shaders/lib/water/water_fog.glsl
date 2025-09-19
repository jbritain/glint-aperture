#ifndef WATER_FOG_GLSL
#define WATER_FOG_GLSL

#include "/lib/common.glsl"
#include "/lib/util/shadow_space.glsl"
#include "/lib/util/phase_functions.glsl"
#include "/lib/buffers/scene_data.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/misc.glsl"

const vec3 water_absorption = vec3(0.3, 0.06, 0.04);
const vec3 water_scattering = vec3(0.01, 0.05, 0.03) * 2.0;
const vec3 water_extinction = water_absorption + water_scattering;
const vec3 water_scattering_albedo = water_scattering / water_extinction;

const float water_density = 1.0;

#define WATER_FOG_STEPS 8

// https://x.com/FewesW/status/1364629939568451587/photo/1
float multiple_scattering_water(float phase, float step_length) {
  float attenuation = 0.2;
  float contribution = 0.2;
  float phase_attenuation = 0.5;

  float a = 1.0;
  float b = 1.0;
  float c = 1.0;
  const int scattering_octaves = 4;

  float luminance = 0.0;

  for (int i = 0; i < scattering_octaves; i++) {
    float transmittance = exp(-a * step_length);

    luminance += b * phase * transmittance;

    a *= attenuation;
    b *= contribution;
    c *= 1.0 - phase_attenuation;
  }
  return luminance;
}

Volume water_fog(vec3 start_pos, vec3 end_pos) {
  vec3 ray_step = (end_pos - start_pos) / WATER_FOG_STEPS;
  float step_length = length(ray_step);
  vec3 ray_pos = start_pos;

  if (distance(start_pos, end_pos) < 0.01) {
    return Volume(vec3(1.0), vec3(0.0));
  }

  vec3 transmittance = vec3(1.0);
  vec3 scattering = vec3(0.0);

  ray_pos += blue_noise(floor(gl_FragCoord.xy), ap.time.frames).r * ray_step;

  vec3 step_transmittance = max0(exp(-step_length * water_extinction));

  float phase = henyey_greenstein_phase(
    dot(normalize(ray_step), world_light_dir),
    0.4
  );
  phase = multiple_scattering_water(phase, step_length);

  for (int i = 0; i < WATER_FOG_STEPS; i++, ray_pos += ray_step) {
    int cascade;
    vec3 shadow_sample_pos = get_shadow_screen_pos(ray_pos, cascade);
    vec3 transmittance_to_sun = vec3(1.0);

    vec3 shadow_map_pixel_size = get_shadow_map_pixel_size(cascade);

    float blocker_distance = 1.0;

    transmittance_to_sun = vec3(
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

      blocker_distance =
        shadow_sample_pos.z -
        translucent_shadow_depth * shadow_map_pixel_size.z;

      transmittance_to_sun *= exp(-max0(blocker_distance) * water_extinction);

    }

    vec3 radiance =
      sunlight_color * phase * transmittance_to_sun +
      skylight_color * isotropic_phase;

    radiance *= step_length;

    scattering += transmittance * radiance;
    transmittance *= step_transmittance;
  }

  scattering *= (1.0 - step_transmittance) * water_scattering_albedo;

  return Volume(transmittance, scattering);
}

#endif // WATER_FOG_GLSL
