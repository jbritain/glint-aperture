#ifndef SHADOWS_GLSL
#define SHADOWS_GLSL

#include "/lib/util/shadow_space.glsl"
#include "/lib/util/misc.glsl"

#define PCSS_MAX_RADIUS 1.0 // 1 block
#define BLOCKER_DISTANCE_SAMPLES 4

vec3 sample_shadow_map(vec3 shadow_screen_pos, int cascade) {
  return vec3(
    texture(
      shadowMapFiltered,
      vec4(shadow_screen_pos.xy, cascade, shadow_screen_pos.z)
    )
  );
}

float get_blocker_depth(vec3 shadow_screen_pos, int cascade) {
  float average_blocker_depth = 0.0;
  int samples = 0;
  vec2 cascade_size = 2.0 / vec2(ap.celestial.projection[cascade][0].x, ap.celestial.projection[cascade][1].y);

  for (int i = 0; i < BLOCKER_DISTANCE_SAMPLES; i++) {
    vec2 offset = vogel_disc_sample(i, BLOCKER_DISTANCE_SAMPLES, 0.0) * PCSS_MAX_RADIUS * cascade_size;

    float blocker_depth = texture(shadowMap, shadow_screen_pos.xz + offset).r;

    if(blocker_depth < shadow_screen_pos.z) {
      average_blocker_depth += blocker_depth;
      samples++;
    }
  }

  return average_blocker_depth / float(samples);
}

struct Shadow_Subsurface_Scatter {
  vec3 shadow;
  vec3 subsurface_scatter;
};

Shadow_Subsurface_Scatter compute_shadowing_and_subsurface_scattering(
  vec3 player_pos,
  vec3 world_normal,
  float subsurface_scattering
) {
  Shadow_Subsurface_Scatter result;

  int cascade;
  vec3 shadow_screen_pos = get_shadow_screen_pos(
    player_pos,
    world_normal,
    cascade
  );

  float blocker_depth = get_blocker_depth(shadow_screen_pos, cascade);
  show(texture(shadowMap, shadow_screen_pos.xy));

  result.shadow = sample_shadow_map(shadow_screen_pos, cascade);

  return result;
}

#endif // SHADOWS_GLSL
