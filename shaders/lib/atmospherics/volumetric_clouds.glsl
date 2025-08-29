#ifndef CLOUDS_GLSL
#define CLOUDS_GLSL

#include "/lib/buffers/scene_data.glsl"
#include "/lib/common.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/phase_functions.glsl"
#include "/lib/atmospherics/atmosphere.glsl"
#include "/lib/util/intersections.glsl"

uniform sampler3D cloud_shape_tex;
uniform sampler3D cloud_detail_tex;
uniform sampler2D cloud_weather_tex;

#define CLOUD_BASE_HEIGHT 400
#define CLOUD_TOP_HEIGHT 1000
#define CLOUD_STEPS 32
#define CLOUD_SUB_STEPS 8

#define CLOUD_EXTINCTION 0.05
#define CLOUD_DENSITY 1.0

float beers_powder(float extinction) {
  return 2.0 * exp(-2.0 * extinction) * exp(-extinction);
}

// https://x.com/FewesW/status/1364629939568451587/photo/1
float multiple_scattering_clouds(float density, float phase) {
  float attenuation = 0.2;
  float contribution = 0.2;
  float phase_attenuation = 0.5;

  float a = 1.0;
  float b = 1.0;
  float c = 1.0;
  const int scattering_octaves = 4;

  float luminance = 0.0;

  for (int i = 0; i < scattering_octaves; i++) {
    float transmittance = beers_powder(density * CLOUD_EXTINCTION * a);

    luminance += b * phase * transmittance;

    a *= attenuation;
    b *= contribution;
    c *= 1.0 - phase_attenuation;
  }
  return luminance;
}

vec3 map_spherical(vec3 world_pos, float radius) {
  radius += earth_radius + 64;
  world_pos.y += earth_radius + 64;
  float angle_x = world_pos.x / radius;
  float angle_z = world_pos.z / radius;

  vec3 curved_pos;
  curved_pos.x = radius * sin(angle_x) * cos(angle_z);
  curved_pos.y = world_pos.y + radius * (1.0 - cos(angle_x) * cos(angle_z));
  curved_pos.z = radius * sin(angle_z) * cos(angle_x);

  curved_pos.y -= earth_radius;

  return curved_pos;
}

float get_cloud_density(
  vec3 pos,
  bool high_quality,
  out float coverage,
  out float height_fraction
) {
  vec3 sample_pos = pos; // floor(pos / 64.0) * 64.0;
  height_fraction = saturate(
    linearstep(CLOUD_BASE_HEIGHT, CLOUD_TOP_HEIGHT, sample_pos.y)
  );

  vec4 low_frequency_noise = texture(
    cloud_shape_tex,
    fract((sample_pos + vec3(0.0, 0.0, world_time_counter) * 10.0) / 2000.0)
  );

  float low_frequency_fbm = saturate(
    low_frequency_noise.g * 0.625 +
      low_frequency_noise.b * 0.25 +
      low_frequency_noise.a * 0.125
  );

  float density = low_frequency_noise.r;
  density = saturate(remap(density, low_frequency_fbm * 0.7, 1.0, 0.0, 1.0));

  // sample_pos = floor(pos / 128.0) * 128.0;

  coverage = max0(
    texture(
      cloud_weather_tex,
      fract((sample_pos.xz + vec2(0.0, world_time_counter) * 10.0) / 50000.0)
    ).r
  );

  // coverage = mix(
  //   coverage,
  //   1.0,
  //   saturate(distance(pos.xz, ap.camera.pos.xz) / 20000.0)
  // );

  if (height_fraction <= 0.15) {
    density *= linearstep(0.0, 0.15, height_fraction);
  } else if (height_fraction >= 0.15) {
    density *= 1.0 - linearstep(0.15, 1.0, height_fraction);
  }

  density = saturate(remap(density, 1.0 - coverage, 1.0, 0.0, 1.0));
  density *= coverage;

  if (!high_quality) {
    return density * CLOUD_DENSITY;
  }

  if (density < 0.01) {
    return 0.0;
  }

  // sample_pos = floor(pos / 32.0) * 32.0;

  vec3 high_frequency_noise = texture(
    cloud_detail_tex,
    fract((sample_pos + vec3(0.0, 0.0, world_time_counter) * 20.0) / 100.0)
  ).rgb;
  float high_frequency_fbm =
    high_frequency_noise.r * 0.625 +
    high_frequency_noise.g * 0.25 +
    high_frequency_noise.b * 0.125;

  high_frequency_fbm =
    0.35 *
    exp(-coverage * 0.75) *
    mix(
      high_frequency_fbm,
      1.0 - high_frequency_fbm,
      saturate(height_fraction)
    );

  density = max0(remap(density, high_frequency_fbm, 1.0, 0.0, 1.0));

  return density * CLOUD_DENSITY;
}

float get_light_from_sun(vec3 ray_pos, vec2 jitter, float phase) {
  // vec3 ray_dir = generate_cone_vector(world_light_dir, jitter, 0.03);
  vec3 ray_dir = world_light_dir;

  vec3 a = ray_pos;
  vec3 b;
  if (!ray_plane_intersection(a, ray_dir, CLOUD_TOP_HEIGHT, b)) {
    if (!ray_plane_intersection(a, ray_dir, CLOUD_BASE_HEIGHT, b)) {
      return 1.0;
    }
  }

  float density = 0.0;

  vec3 previous_sample_pos = a;
  for (int i = 0; i < CLOUD_SUB_STEPS; i++) {
    float progress = float(i + jitter.y) / float(CLOUD_SUB_STEPS);
    vec3 sample_pos = mix(a, b, exp(10.0 * (progress - 1.0)));

    float temp1;
    float temp2;

    density +=
      get_cloud_density(sample_pos, false, temp1, temp2) *
      distance(previous_sample_pos, sample_pos);

    previous_sample_pos = sample_pos;
  }

  // return beers_powder(density * CLOUD_EXTINCTION) * phase;
  return multiple_scattering_clouds(density, phase);
}

// the origin is in world space
// TODO: not that?
vec4 get_clouds(vec3 origin, vec3 player_pos, bool sky, bool high_quality) {
  vec3 ray_dir = normalize(player_pos);

  vec3 a;
  vec3 b;
  if (!ray_plane_intersection(origin, ray_dir, CLOUD_BASE_HEIGHT, a)) {
    a = ap.camera.pos;
  }

  if (!ray_plane_intersection(origin, ray_dir, CLOUD_TOP_HEIGHT, b)) {
    b = ap.camera.pos;
  }

  if (distance(ap.camera.pos, a) > distance(ap.camera.pos, b)) {
    vec3 c = a;
    a = b;
    b = c;
  }

  vec3 world_pos = player_pos + ap.camera.pos;

  if (!sky) {
    if (world_pos.y > CLOUD_BASE_HEIGHT && world_pos.y < CLOUD_TOP_HEIGHT) {
      b = world_pos;
    } else if (
      world_pos.y > CLOUD_TOP_HEIGHT && ap.camera.pos.y > CLOUD_TOP_HEIGHT ||
      world_pos.y < CLOUD_BASE_HEIGHT && ap.camera.pos.y < CLOUD_BASE_HEIGHT
    ) {
      return vec4(0.0, 0.0, 0.0, 1.0);
    }
  }

  vec3 ray_step = (b - a) / CLOUD_STEPS;
  float step_length = length(ray_step);
  vec3 ray_pos = a;
  vec2 jitter = blue_noise(
    floor(gl_FragCoord.xy),
    high_quality
      ? ap.time.frames
      : 0
  ).xy;
  ray_pos += ray_step * jitter.x;
  float cos_theta = dot(ray_dir, world_light_dir);

  float transmittance = 1.0;
  vec3 scatter = vec3(0.0);

  // float phase = dual_lobe_hg_phase(cos_theta, 0.8, -0.5, 0.5);
  float phase = mix(
    hg_draine_phase(cos_theta, 11),
    henyey_greenstein_phase(cos_theta, 0.2),
    1.0 - saturate(cos_theta)
  );

  for (
    int i = 0;
    i <
    (high_quality
      ? int(mix(CLOUD_STEPS, CLOUD_STEPS * 2, 1.0 - abs(ray_dir.y)))
      : CLOUD_STEPS / 2);
    i++, ray_pos += ray_step
  ) {
    float height_fraction;
    float coverage;
    float density = get_cloud_density(
      ray_pos,
      high_quality,
      coverage,
      height_fraction
    );

    float sample_transmittance = exp(-density * step_length * CLOUD_EXTINCTION);

    vec3 radiance = sunlight_color * get_light_from_sun(ray_pos, jitter, phase);
    radiance +=
      skylight_color *
      isotropic_phase *
      sqrt(1.0 - height_fraction * coverage) *
      (CLOUD_EXTINCTION * 10.0); // I hate this

    scatter +=
      transmittance *
      (radiance * (1.0 - saturate(sample_transmittance)) / CLOUD_EXTINCTION);
    transmittance *= sample_transmittance;

    if (transmittance < 0.01) {
      break;
    }

  }

  return vec4(scatter, transmittance);
}

#endif // CLOUDS_GLSL
