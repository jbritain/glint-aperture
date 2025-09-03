#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/atmospherics/clouds.glsl"
#include "/lib/util/space_conversions.glsl"

in vec2 uv;

layout(location = 0) out float cloud_shadow;

float get_transmittance_to_sun(vec3 ray_pos) {
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
    float progress = float(i) / float(CLOUD_SUB_STEPS);
    vec3 sample_pos = mix(a, b, exp(10.0 * (progress - 1.0)));

    float temp1;
    float temp2;

    density +=
      get_cloud_density(sample_pos, false, temp1, temp2) *
      distance(previous_sample_pos, sample_pos);

    previous_sample_pos = sample_pos;
  }

  return exp(-density * CLOUD_EXTINCTION);
}

void main() {
  vec3 shadow_screen_pos = vec3(uv, 1.0);
  vec3 shadow_view_pos = project_and_divide(vec4(shadow_screen_pos * 2.0 - 1.0, 1.0), ap.celestial.projectionInv[CASCADES-1]);
  vec3 player_pos = (ap.celestial.viewInv * vec4(shadow_view_pos, 1.0)).xyz;
  vec3 world_pos = player_pos + ap.camera.pos;

  ray_plane_intersection(world_pos, world_light_dir, CLOUD_BASE_HEIGHT, world_pos);

  cloud_shadow = get_transmittance_to_sun(world_pos);
}
