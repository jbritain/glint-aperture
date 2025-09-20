#ifndef SHADOWS_GLSL
#define SHADOWS_GLSL

#include "/lib/util/shadow_space.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/dither.glsl"

#define PCSS_MAX_RADIUS 2.0 // 1 block

#define PCF_SAMPLES 8
#define BLOCKER_DISTANCE_SAMPLES 8

vec3 sample_shadow_map(vec3 shadow_screen_pos, int cascade) {
  float opaque_shadow = texture(
    solidShadowMapFiltered,
    vec4(shadow_screen_pos.xy, cascade, shadow_screen_pos.z)
  );

  if (opaque_shadow < 0.01) {
    return vec3(opaque_shadow);
  }

  float translucent_shadow = texture(
    shadowMapFiltered,
    vec4(shadow_screen_pos.xy, cascade, shadow_screen_pos.z)
  );

  vec4 shadow_color = texture(
    shadow_color_tex,
    vec3(shadow_screen_pos.xy, cascade)
  );
  shadow_color.rgb = pow(shadow_color.rgb, vec3(GAMMA));

  return mix(
    shadow_color.rgb * (1.0 - shadow_color.a) * opaque_shadow,
    vec3(1.0),
    translucent_shadow
  );
}

float get_blocker_distance(
  vec3 shadow_screen_pos,
  int cascade,
  vec2 radius,
  float jitter
) {
  float average_blocker_distance = 0.0;
  int samples = 0;

  for (int i = 0; i < BLOCKER_DISTANCE_SAMPLES; i++) {
    vec2 offset =
      vogel_disc_sample(i, BLOCKER_DISTANCE_SAMPLES, jitter) * radius;

    float blocker_depth = texture(
      shadowMap,
      vec3(shadow_screen_pos.xy + offset, cascade)
    ).r;

    if (blocker_depth < shadow_screen_pos.z) {
      average_blocker_distance += shadow_screen_pos.z - blocker_depth;
      samples++;
    }
  }

  return average_blocker_distance / float(samples);
}

vec3 sample_pcf(
  vec3 shadow_screen_pos,
  int cascade,
  vec2 radius,
  float jitter
) {
  vec3 shadow = vec3(0.0);

  for (int i = 0; i < PCF_SAMPLES; i++) {
    vec2 offset =
      vogel_disc_sample(i, BLOCKER_DISTANCE_SAMPLES, jitter) * radius;

    shadow += sample_shadow_map(shadow_screen_pos + vec3(offset, 0.0), cascade);
  }

  return shadow / float(PCF_SAMPLES);
}

/*
  The blocker distance is stored in the alpha channel, stored as a 0-1
*/
vec4 compute_shadowing_and_blocker_distance(
  vec3 player_pos,
  vec3 world_normal
) {
  vec4 shadow;

  float jitter = interleaved_gradient_noise(
    floor(gl_FragCoord.xy),
    ap.time.frames
  );

  int cascade;
  vec3 shadow_screen_pos = get_shadow_screen_pos(
    player_pos,
    world_normal,
    cascade
  );

  if (cascade == CASCADES) return vec4(1.0);

  vec3 shadow_map_pixel_size = get_shadow_map_pixel_size(cascade);

  float blocker_distance = get_blocker_distance(
    shadow_screen_pos,
    cascade,
    PCSS_MAX_RADIUS / shadow_map_pixel_size.xy,
    jitter
  );

  // all cascades have the same depth range
  vec2 sample_radius = max(
    blocker_distance * (PCSS_MAX_RADIUS / shadow_map_pixel_size.xy),
    rcp(textureSize(shadowMap, 0).xy) * 2.0
  );
  shadow.rgb = sample_pcf(shadow_screen_pos, cascade, sample_radius, jitter);

  vec3 cloud_shadow_pos = get_shadow_screen_pos_cascade(
    player_pos,
    CASCADES - 1
  );
  vec2 cloud_shadow = texture(cloud_shadow_tex, cloud_shadow_pos.xy).rg;
  shadow.rgb *= cloud_shadow.r * cloud_shadow.g;

  shadow.a = blocker_distance;

  return shadow;
}

#endif // SHADOWS_GLSL
