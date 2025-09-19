#ifndef CLOUDS_GLSL
#define CLOUDS_GLSL

#include "/lib/buffers/scene_data.glsl"
#include "/lib/common.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/phase_functions.glsl"
#include "/lib/atmospherics/atmosphere.glsl"
#include "/lib/util/intersections.glsl"
#include "/lib/util/shadow_space.glsl"

uniform sampler3D cloud_shape_tex;
uniform sampler3D cloud_detail_tex;
uniform sampler2D cloud_weather_tex;

struct CloudLayer {
  float base_height;
  float mid_height_fraction;
  float top_height;
  float samples;
  float light_samples;
  float density;
  uint component; // when the cloud is stored as a single value in a texture, which component does it occupy?
  bvec2 sample_shadows; // which components in the cloud shadow map should cast a shadow?
};

CloudLayer cumulus_cloud_layer = CloudLayer(
  400,
  0.15,
  1000,
  32,
  8,
  0.5 + 2.0 * ap.world.thunder,
  0,
  bvec2(false, true)
);

CloudLayer stratus_cloud_layer = CloudLayer(
  1200,
  0.15,
  1800,
  16,
  4,
  0.2 + 2.0 * ap.world.thunder,
  1,
  bvec2(false, false)
);

CloudLayer[] cloud_layers = CloudLayer[](
  cumulus_cloud_layer,
  stratus_cloud_layer
);

// #define VOXEL_CLOUDS

#ifdef VOXEL_CLOUDS
#define WIND_SPEED 0.0
#else
#define WIND_SPEED 5.0
#endif

#define MAX_CLOUD_DIST 10000

#define CLOUD_EXTINCTION 0.1

// https://x.com/FewesW/status/1364629939568451587/photo/1
float multiple_scattering_clouds(float density, float phase) {
  float attenuation = 0.6;
  float contribution = 0.6;
  float phase_attenuation = 0.6;

  float a = 1.0;
  float b = 1.0;
  float c = 1.0;

  float luminance = 0.0;

  for (int i = 0; i < 4; i++) {
    float transmittance = exp(-density * CLOUD_EXTINCTION * a);

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
  CloudLayer cloud_layer,
  vec3 pos,
  bool high_quality,
  out float coverage,
  out float height_fraction
) {
  vec3 sample_pos = pos;

  #ifdef VOXEL_CLOUDS
  sample_pos = floor(pos / 64.0) * 64.0;
  #endif

  height_fraction = saturate(
    linearstep(cloud_layer.base_height, cloud_layer.top_height, sample_pos.y)
  );

  vec4 low_frequency_noise = texture(
    cloud_shape_tex,
    fract(
      (sample_pos + vec3(0.0, 0.0, world_time_counter) * WIND_SPEED) / 2000.0
    )
  );

  float low_frequency_fbm = saturate(
    low_frequency_noise.g * 0.625 +
      low_frequency_noise.b * 0.25 +
      low_frequency_noise.a * 0.125
  );

  float density = low_frequency_noise.r;
  density = saturate(remap(density, low_frequency_fbm * 0.7, 1.0, 0.0, 1.0));

  #ifdef VOXEL_CLOUDS
  sample_pos = floor(pos / 32.0) * 32.0;
  #endif

  coverage = max0(
    texture(
      cloud_weather_tex,
      fract(
        (sample_pos.xz + vec2(0.0, world_time_counter) * WIND_SPEED) / 70000.0
      )
    )[cloud_layer.component]
  );

  // coverage = mix(
  //   coverage,
  //   1.0,
  //   saturate(distance(pos.xz, ap.camera.pos.xz) / 20000.0)
  // );

  if (height_fraction <= cloud_layer.mid_height_fraction) {
    density *= linearstep(
      0.0,
      cloud_layer.mid_height_fraction,
      height_fraction
    );
  } else if (height_fraction >= cloud_layer.mid_height_fraction) {
    density *=
      1.0 - linearstep(cloud_layer.mid_height_fraction, 1.0, height_fraction);
  }

  density = saturate(remap(density, 1.0 - coverage, 1.0, 0.0, 1.0));
  density *= coverage;

  if (high_quality && density > 1e-6) {
    #ifdef VOXEL_CLOUDS
    sample_pos = floor(pos / 16.0) * 16.0;
    #endif

    vec3 high_frequency_noise = texture(
      cloud_detail_tex,
      fract(
        (sample_pos + vec3(0.0, 0.0, world_time_counter) * WIND_SPEED * 2.0) /
          100.0
      )
    ).rgb;
    float high_frequency_fbm =
      high_frequency_noise.r * 0.625 +
      high_frequency_noise.g * 0.25 +
      high_frequency_noise.b * 0.125;

    // high_frequency_fbm = pow3(high_frequency_fbm);

    high_frequency_fbm =
      0.5 *
      exp(-coverage * 0.75) *
      mix(
        high_frequency_fbm,
        1.0 - high_frequency_fbm,
        saturate(height_fraction)
      );

    density = max0(remap(density, high_frequency_fbm, 1.0, 0.0, 1.0));
  }

  #ifdef VOXEL_CLOUDS

  density = pow(density, 0.5);
  density *= 2.0;
  #endif

  return pow(density, 0.7) * cloud_layer.density;
}

float get_light_from_sun(
  CloudLayer cloud_layer,
  vec3 ray_pos,
  vec2 jitter,
  float phase
) {
  // vec3 ray_dir = generate_cone_vector(world_light_dir, jitter, 0.03);
  vec3 ray_dir = world_light_dir;

  vec3 a = ray_pos;
  vec3 b;
  if (!ray_plane_intersection(a, ray_dir, cloud_layer.top_height, b)) {
    if (!ray_plane_intersection(a, ray_dir, cloud_layer.base_height, b)) {
      return 1.0;
    }
  }

  float density = 0.0;

  vec3 previous_sample_pos = a;
  for (int i = 0; i < cloud_layer.light_samples; i++) {
    float progress = float(i + jitter.y) / float(cloud_layer.light_samples);
    vec3 sample_pos = mix(a, b, exp(10.0 * (progress - 1.0)));

    float temp1;
    float temp2;

    density +=
      get_cloud_density(cloud_layer, sample_pos, false, temp1, temp2) *
      distance(previous_sample_pos, sample_pos);

    previous_sample_pos = sample_pos;
  }

  // return exp(-density * CLOUD_EXTINCTION) * phase;
  float light = multiple_scattering_clouds(density, phase);
  vec3 cloud_shadow_pos = get_shadow_screen_pos_cascade(
    ray_pos - ap.camera.pos,
    CASCADES - 1
  );

  return light;
}

// the origin is in world space
// TODO: not that?
vec4 get_clouds(
  CloudLayer cloud_layer,
  vec3 origin,
  vec3 player_pos,
  bool sky,
  bool high_quality
) {
  vec3 ray_dir = normalize(player_pos);

  vec3 a;
  vec3 b;
  if (!ray_plane_intersection(origin, ray_dir, cloud_layer.base_height, a)) {
    a = ap.camera.pos;
  }

  if (!ray_plane_intersection(origin, ray_dir, cloud_layer.top_height, b)) {
    b = ap.camera.pos;
  }

  if (distance(ap.camera.pos, a) > distance(ap.camera.pos, b)) {
    vec3 c = a;
    a = b;
    b = c;
  }

  vec3 world_pos = player_pos + ap.camera.pos;

  if (!sky) {
    if (
      world_pos.y > cloud_layer.base_height &&
      world_pos.y < cloud_layer.top_height
    ) {
      b = world_pos;
    } else if (
      world_pos.y > cloud_layer.top_height &&
        ap.camera.pos.y > cloud_layer.top_height ||
      world_pos.y < cloud_layer.base_height &&
        ap.camera.pos.y < cloud_layer.base_height
    ) {
      return vec4(0.0, 0.0, 0.0, 1.0);
    }
  }

  if (distance(a, b) > MAX_CLOUD_DIST) {
    b = a + ray_dir * MAX_CLOUD_DIST;
  }

  vec3 ray_step = (b - a) / cloud_layer.samples;
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

  float phase = mix(
    hg_draine_phase(cos_theta, 11),
    henyey_greenstein_phase(cos_theta, 0.2),
    1.0 - saturate(cos_theta)
  );

  for (
    int i = 0;
    i <
    (high_quality
      ? int(
        mix(cloud_layer.samples, cloud_layer.samples * 2, 1.0 - abs(ray_dir.y))
      )
      : cloud_layer.samples / 2);
    i++, ray_pos += ray_step
  ) {
    float height_fraction;
    float coverage;
    float density = get_cloud_density(
      cloud_layer,
      ray_pos,
      high_quality,
      coverage,
      height_fraction
    );

    float sample_transmittance = exp(-density * step_length * CLOUD_EXTINCTION);

    vec3 radiance =
      sunlight_color * get_light_from_sun(cloud_layer, ray_pos, jitter, phase);
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
