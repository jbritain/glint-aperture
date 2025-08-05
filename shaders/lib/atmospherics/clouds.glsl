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

float get_cloud_density(vec3 pos) {
  float height_fraction = saturate(
    smoothstep(CLOUD_BASE_HEIGHT, CLOUD_TOP_HEIGHT, pos.y)
  );

  vec4 low_frequency_noise = texture(cloud_shape_tex, fract(pos / 5000.0));

  float low_frequency_fbm =
    low_frequency_noise.g * 0.625 +
    low_frequency_noise.b * 0.25 +
    low_frequency_noise.a * 0.125;

  float density = remap(
    low_frequency_noise.r,
    -(1.0 - low_frequency_fbm),
    1.0,
    0.0,
    1.0
  );

  float coverage = texture(cloud_weather_tex, fract(pos.xz / 10000.0)).r;
  density = pow2(
    smoothstep(0.8 - coverage * 0.3, 0.85 - coverage * 0.3, density)
  );

  if (height_fraction <= 0.2) {
    density *= sqrt(smoothstep(0.0, 0.2, height_fraction));
  } else if (height_fraction >= 0.3) {
    density *= 1.0 - smoothstep(0.3, 1.0, height_fraction);
  }
  density *= coverage;

  if (density < 0.01) {
    return 0.0;
  }

  vec3 high_frequency_noise = texture(cloud_detail_tex, fract(pos / 500.0)).rgb;
  float high_frequency_fbm = smoothstep(
    0.45,
    0.5,
    high_frequency_noise.r * 0.625 +
      high_frequency_noise.g * 0.25 +
      high_frequency_noise.b * 0.125
  );

  high_frequency_fbm = mix(
    high_frequency_fbm,
    1.0 - high_frequency_fbm,
    saturate(height_fraction * 10.0)
  );

  density = max0(remap(density, high_frequency_fbm * 0.2, 1.0, 0.0, 1.0));

  if (height_fraction <= 0.2) {
    density *= sqrt(smoothstep(0.0, 0.2, height_fraction));
  } else if (height_fraction >= 0.3) {
    density *= 1.0 - smoothstep(0.3, 1.0, height_fraction);
  }

  return density * 0.1;
}

float get_transmittance_towards_sun(vec3 ray_pos, vec2 jitter) {
  vec3 ray_dir = generate_cone_vector(world_light_dir, jitter, 0.01);

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

  float beers_law = exp(-density * CLOUD_EXTINCTION);
  float powder = 1.0 - exp(-density * CLOUD_EXTINCTION * 2.0);

  return beers_law; //2.0 * powder * beers_law;
}

vec4 get_clouds(vec3 origin, vec3 ray_dir) {
  vec3 a;
  vec3 b;
  if (!ray_plane_intersection(origin, ray_dir, CLOUD_BASE_HEIGHT, a)) {
    return vec4(vec3(0.0), 1.0);
  }

  if (!ray_plane_intersection(origin, ray_dir, CLOUD_TOP_HEIGHT, b)) {
    return vec4(vec3(0.0), 1.0);
  }

  vec3 ray_step = (b - a) / CLOUD_STEPS;
  float step_length = length(ray_step);
  vec3 ray_pos = a;
  vec2 jitter = blue_noise(floor(gl_FragCoord.xy), ap.time.frames).xy;
  ray_pos += ray_step * jitter.x;

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
      sunlight_color * get_transmittance_towards_sun(ray_pos, jitter);
    radiance += skylight_color * transmittance;

    scatter +=
      transmittance *
      (radiance * (1.0 - saturate(sample_transmittance)) / CLOUD_EXTINCTION);
    transmittance *= sample_transmittance;

  }

  scatter *= dual_lobe_hg_phase(dot(ray_dir, world_light_dir), 0.8, -0.5, 0.5);

  return vec4(scatter, transmittance);
}

#endif // CLOUDS_GLSL
