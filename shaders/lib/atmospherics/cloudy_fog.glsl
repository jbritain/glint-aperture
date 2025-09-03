#ifndef CLOUDY_FOG_GLSL
#define CLOUDY_FOG_GLSL

#include "/lib/common.glsl"
#include "/lib/util/shadow_space.glsl"
#include "/lib/util/phase_functions.glsl"
#include "/lib/buffers/scene_data.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/misc.glsl"

#define CLOUDY_FOG_STEPS 16
#define CLOUDY_FOG_SUB_STEPS 1

#define CLOUDY_FOG_BASE_HEIGHT -63
#define CLOUDY_FOG_CENTRE_HEIGHT 0
#define CLOUDY_FOG_TOP_HEIGHT mix(150, 1000, ap.world.rain)

#define CLOUDY_FOG_EXTINCTION 0.1
#define CLOUDY_FOG_DENSITY 1.0

float get_cloudy_fog_density(vec3 pos) {
  float density =
    pos.y <= CLOUDY_FOG_CENTRE_HEIGHT
      ? linearstep(CLOUDY_FOG_BASE_HEIGHT, CLOUDY_FOG_CENTRE_HEIGHT, pos.y)
      : 1.0 -
      linearstep(CLOUDY_FOG_CENTRE_HEIGHT, CLOUDY_FOG_TOP_HEIGHT, pos.y);

  density = pow3(density);

  density *= smoothstep(
    0.4,
    1.0,
    texture(
      cloud_shape_tex,
      fract((pos + vec3(0.0, 0.0, world_time_counter) * 10.0) / 2000.0)
    ).r
  );

  density *= mix(
    saturate(pow3(1.0 - abs(world_light_dir.y))) * 0.9 + 0.1,
    0.1,
    ap.world.rain
  );

  return density * CLOUDY_FOG_DENSITY;
}

// https://x.com/FewesW/status/1364629939568451587/photo/1
float multiple_scattering_cloudy_fog(float density, float phase) {
  float attenuation = 0.2;
  float contribution = 0.2;
  float phase_attenuation = 0.5;

  float a = 1.0;
  float b = 1.0;
  float c = 1.0;
  float g = 0.85;
  const int scattering_octaves = 4;

  float luminance = 0.0;

  for (int i = 0; i < scattering_octaves; i++) {
    float transmittance = exp(-density * CLOUDY_FOG_EXTINCTION * a);

    luminance += b * phase * transmittance;

    a *= attenuation;
    b *= contribution;
    c *= 1.0 - phase_attenuation;
  }
  return luminance;
}

float get_light_from_sun(vec3 ray_pos, float jitter, float phase) {
  vec3 ray_dir = world_light_dir;

  vec3 a = ray_pos;
  vec3 b;
  if (!ray_plane_intersection(a, ray_dir, CLOUDY_FOG_TOP_HEIGHT, b)) {
    return 1.0;
  }

  float density = 0.0;

  vec3 previous_sample_pos = a;
  for (int i = 0; i < CLOUDY_FOG_SUB_STEPS; i++) {
    float progress = float(i + jitter) / float(CLOUDY_FOG_SUB_STEPS);
    vec3 sample_pos = mix(a, b, exp(10.0 * (progress - 1.0)));

    density +=
      get_cloudy_fog_density(sample_pos) *
      distance(previous_sample_pos, sample_pos);

    previous_sample_pos = sample_pos;
  }

  return exp(-density * CLOUDY_FOG_EXTINCTION);
  // return multiple_scattering_cloudy_fog(density, phase);
}

Volume cloudy_fog(vec3 start_pos, vec3 end_pos, bool sky) {
  vec3 transmittance = vec3(1.0);
  vec3 scattering = vec3(0.0);

  if (
    start_pos.y > CLOUDY_FOG_TOP_HEIGHT && end_pos.y > CLOUDY_FOG_TOP_HEIGHT ||
    start_pos.y < CLOUDY_FOG_BASE_HEIGHT && end_pos.y < CLOUDY_FOG_BASE_HEIGHT
  ) {
    return Volume(transmittance, scattering);
  }

  vec2 jitter = blue_noise(floor(gl_FragCoord.xy), ap.time.frames).xy;

  vec3 ray_dir = normalize(end_pos - start_pos);

  float cos_theta = dot(ray_dir, world_light_dir);
  float phase = mix(
    hg_draine_phase(cos_theta, 8),
    henyey_greenstein_phase(cos_theta, 0.2),
    1.0 - saturate(cos_theta)
  );

  vec3 a;
  vec3 b;
  if (!ray_plane_intersection(start_pos, ray_dir, CLOUDY_FOG_BASE_HEIGHT, a)) {
    a = ap.camera.pos;
  }

  if (!ray_plane_intersection(start_pos, ray_dir, CLOUDY_FOG_TOP_HEIGHT, b)) {
    b = ap.camera.pos;
  }

  if (distance(ap.camera.pos, a) > distance(ap.camera.pos, b)) {
    swap(a, b);
  }

  if (
    end_pos.y > CLOUDY_FOG_BASE_HEIGHT &&
    end_pos.y < CLOUDY_FOG_TOP_HEIGHT &&
    !sky
  ) {
    b = end_pos;
  }

  vec3 previous_ray_pos = start_pos;

  for (int i = 0; i < CLOUDY_FOG_STEPS; i++) {
    float progress = float(i + jitter) / float(CLOUDY_FOG_STEPS);

    vec3 ray_pos = mix(
      a,
      b,
      start_pos == ap.camera.pos
        ? exp(10.0 * (progress - 1.0))
        : progress
    );

    int cascade;
    vec3 shadow_sample_pos = get_shadow_screen_pos(
      ray_pos - ap.camera.pos,
      cascade
    );

    float shadow = 1.0;
    float density =
      get_cloudy_fog_density(ray_pos) * distance(ray_pos, previous_ray_pos);
    float sample_transmittance = exp(-density * CLOUDY_FOG_EXTINCTION);
    if (saturate(shadow_sample_pos) == shadow_sample_pos) {
      vec3 shadow_map_pixel_size = get_shadow_map_pixel_size(cascade);

      shadow = texture(
        shadowMapFiltered,
        vec4(shadow_sample_pos.xy, cascade, shadow_sample_pos.z)
      ).r;

      shadow_sample_pos = get_shadow_screen_pos_cascade(
        ray_pos - ap.camera.pos,
        CASCADES - 1
      );
      shadow *= texture(cloud_shadow_tex, shadow_sample_pos.xy).r;
    }

    vec3 radiance =
      sunlight_color *
        get_light_from_sun(ray_pos, jitter.y, phase) *
        shadow *
        phase +
      skylight_color * isotropic_phase * ap.camera.brightness.y;

    scattering +=
      transmittance *
      (radiance *
        (1.0 - saturate(sample_transmittance)) /
        CLOUDY_FOG_EXTINCTION);
    transmittance *= sample_transmittance;

    previous_ray_pos = ray_pos;
  }

  return Volume(transmittance, scattering);
}

#endif // CLOUDY_FOG_GLSL
