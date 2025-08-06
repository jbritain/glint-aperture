#ifndef CLOUDS_GLSL
#define CLOUDS_GLSL

#include "/lib/buffers/scene_data.glsl"
#include "/lib/common.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/phase_functions.glsl"

uniform sampler3D cloud_shape_tex;
uniform sampler3D cloud_detail_tex;
uniform sampler2D cloud_weather_tex;

#define CLOUD_BASE_HEIGHT 400
#define CLOUD_TOP_HEIGHT 1000
#define CLOUD_STEPS 16
#define CLOUD_SUB_STEPS 8

#define CLOUD_EXTINCTION 0.1

// https://x.com/FewesW/status/1364629939568451587/photo/1
float multiple_scattering(float density, float cos_theta) {
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
    float phase = dual_lobe_hg_phase(cos_theta, 0.8, -0.5, 0.5);

    float beers = exp(-density * CLOUD_EXTINCTION * a);

    luminance += b * phase * beers;

    a *= attenuation;
    b *= contribution;
    c *= 1.0 - phase_attenuation;
  }
  return luminance;
}

float get_cloud_density(vec3 pos) {
  vec3 rounded_pos = pos; //floor(pos / 64.0) * 64.0;
  float height_fraction = saturate(
    linearstep(CLOUD_BASE_HEIGHT, CLOUD_TOP_HEIGHT, rounded_pos.y)
  );

  vec4 low_frequency_noise = texture(
    cloud_shape_tex,
    fract(rounded_pos / 2000.0)
  );

  float low_frequency_fbm = saturate(
    low_frequency_noise.g * 0.625 +
      low_frequency_noise.b * 0.25 +
      low_frequency_noise.a * 0.125
  );

  float density = low_frequency_noise.r;
  density = saturate(remap(density, low_frequency_fbm * 0.7, 1.0, 0.0, 1.0));

  // rounded_pos = floor(pos / 128.0) * 128.0;
  float coverage = texture(
    cloud_weather_tex,
    fract(rounded_pos.xz / 50000.0)
  ).r;

  if (height_fraction <= 0.15) {
    density *= linearstep(0.0, 0.15, height_fraction);
  } else if (height_fraction >= 0.3) {
    density *= 1.0 - linearstep(0.3, 1.0, height_fraction);
  }

  density = saturate(remap(density, 1.0 - coverage, 1.0, 0.0, 1.0));
  density *= coverage;

  if (density < 0.01) {
    return 0.0;
  }

  // rounded_pos = floor(pos / 32.0) * 32.0;
  vec3 high_frequency_noise = texture(
    cloud_detail_tex,
    fract(rounded_pos / 100.0)
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

  return density * 2.0;
}

float get_transmittance_towards_sun(
  vec3 ray_pos,
  vec2 jitter,
  float cos_theta
) {
  vec3 ray_dir = generate_cone_vector(world_light_dir, jitter, 0.03);

  vec3 a = ray_pos;
  vec3 b;
  if (!ray_plane_intersection(a, ray_dir, CLOUD_TOP_HEIGHT, b)) {
    return 1.0;
  }

  float density = 0.0;

  vec3 previous_sample_pos = a;
  for (int i = 0; i < CLOUD_SUB_STEPS; i++) {
    float progress = float(i + jitter.y) / float(CLOUD_SUB_STEPS);
    vec3 sample_pos = mix(a, b, exp(10.0 * (progress - 1.0)));

    density +=
      get_cloud_density(sample_pos) * distance(previous_sample_pos, sample_pos);

    previous_sample_pos = sample_pos;
  }

  return multiple_scattering(density, cos_theta);
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
    texture(
      sky_irradiance_lut_tex,
      cartesian_to_spherical(vec3(0.0, 1.0, 0.0)) / TAU
    ).rgb *
    henyey_greenstein_phase(0.0, 0.0);

  for (int i = 0; i < CLOUD_STEPS; i++, ray_pos += ray_step) {
    float density = get_cloud_density(ray_pos);

    float sample_transmittance = exp(-density * step_length * CLOUD_EXTINCTION);

    vec3 radiance =
      sunlight_color *
      get_transmittance_towards_sun(ray_pos, jitter, cos_theta);
    radiance += skylight_color * transmittance;

    scatter +=
      transmittance *
      (radiance * (1.0 - saturate(sample_transmittance)) / CLOUD_EXTINCTION);
    transmittance *= sample_transmittance;

  }

  return vec4(scatter, transmittance);
}

#endif // CLOUDS_GLSL
