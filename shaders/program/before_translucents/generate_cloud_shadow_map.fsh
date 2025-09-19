#version 460 compatibility

#include "/lib/common.glsl"

uniform sampler2D cloud_shadow_tex;

#include "/lib/atmospherics/clouds.glsl"
#include "/lib/util/space_conversions.glsl"

in vec2 uv;

layout(location = 0) out vec2 cloud_shadow;

float get_transmittance_to_sun(CloudLayer cloud_layer, vec3 origin) {
  vec3 ray_dir = world_light_dir;

  vec3 a;
  vec3 b;
  ray_plane_intersection(origin, ray_dir, cloud_layer.base_height, a);
  ray_plane_intersection(origin, ray_dir, cloud_layer.top_height, b);

  float density = 0.0;

  vec3 previous_sample_pos = a;
  for (int i = 0; i < cloud_layer.light_samples; i++) {
    float progress = float(i) / float(cloud_layer.light_samples);
    vec3 sample_pos = mix(a, b, exp(10.0 * (progress - 1.0)));

    float temp1;
    float temp2;

    density +=
      get_cloud_density(cloud_layer, sample_pos, false, temp1, temp2) *
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

  ray_plane_intersection(world_pos, world_light_dir, cumulus_cloud_layer.base_height, world_pos);
  cloud_shadow.r = get_transmittance_to_sun(cumulus_cloud_layer, world_pos);

  
  cloud_shadow.r = get_transmittance_to_sun(stratus_cloud_layer, world_pos);
}
