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
#define CLOUD_STEPS 16
#define CLOUD_SUB_STEPS 8

#define CLOUD_EXTINCTION 0.05
#define CLOUD_DENSITY 2.0

float beers_powder(float extinction) {
  return mix(
    1.0 - exp(-2.0 * extinction),
    exp(-extinction),
    smoothstep(0.4, 0.6, extinction)
  );
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

float get_cloud_density(vec3 pos, bool high_quality) {
  float height_fraction = saturate(
    linearstep(CLOUD_BASE_HEIGHT, CLOUD_TOP_HEIGHT, pos.y)
  );

  vec4 low_frequency_noise = texture(
    cloud_shape_tex,
    fract((pos + vec3(0.0, 0.0, world_time_counter) * 10.0) / 2000.0)
  );

  float low_frequency_fbm = saturate(
    low_frequency_noise.g * 0.625 +
      low_frequency_noise.b * 0.25 +
      low_frequency_noise.a * 0.125
  );

  float density = low_frequency_noise.r;
  density = saturate(remap(density, low_frequency_fbm * 0.7, 1.0, 0.0, 1.0));

  float coverage = max0(
    texture(
      cloud_weather_tex,
      fract((pos.xz + vec2(0.0, world_time_counter) * 10.0) / 50000.0)
    ).r
  );

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

  vec3 high_frequency_noise = texture(
    cloud_detail_tex,
    fract((pos + vec3(0.0, 0.0, world_time_counter) * 20.0) / 100.0)
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

    density +=
      get_cloud_density(sample_pos, false) *
      distance(previous_sample_pos, sample_pos);

    previous_sample_pos = sample_pos;
  }

  return multiple_scattering_clouds(density, phase);
}

vec4 get_clouds(vec3 origin, vec3 ray_dir) {
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

  vec3 ray_step = (b - a) / CLOUD_STEPS;
  float step_length = length(ray_step);
  vec3 ray_pos = a;
  vec2 jitter = blue_noise(floor(gl_FragCoord.xy), ap.time.frames).xy;
  ray_pos += ray_step * jitter.x;
  float cos_theta = dot(ray_dir, world_light_dir);

  float transmittance = 1.0;
  vec3 scatter = vec3(0.0);

  vec3 skylight_color =
    texture(sky_irradiance_lut_tex, cartesian_to_spherical(ray_dir) / TAU).rgb *
    isotropic_phase;

  float phase = dual_lobe_hg_phase(cos_theta, 0.8, -0.5, 0.1);
  // float phase = hg_draine_phase(cos_theta, 10);

  for (int i = 0; i < CLOUD_STEPS; i++, ray_pos += ray_step) {
    float density = get_cloud_density(ray_pos, true);

    float sample_transmittance = exp(-density * step_length * CLOUD_EXTINCTION);

    vec3 radiance = sunlight_color * get_light_from_sun(ray_pos, jitter, phase);
    radiance += skylight_color * CLOUD_EXTINCTION * 10.0;

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
