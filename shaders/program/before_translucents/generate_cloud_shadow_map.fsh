#version 460 compatibility

#include "/lib/common.glsl"

uniform sampler2D cloud_shadow_tex;


#include "/lib/atmospherics/clouds.glsl"
#include "/lib/util/space_conversions.glsl"

in vec2 uv;

layout(location = 0) out float cloud_shadow;



void main() {
  vec3 shadow_screen_pos = vec3(uv, 1.0);
  vec3 shadow_view_pos = project_and_divide(vec4(shadow_screen_pos * 2.0 - 1.0, 1.0), ap.celestial.projectionInv[CASCADES-1]);
  vec3 player_pos = (ap.celestial.viewInv * vec4(shadow_view_pos, 1.0)).xyz;
  vec3 world_pos = player_pos + ap.camera.pos;

  cloud_shadow = get_transmittance_to_sun(cumulus_cloud_layer, world_pos);
  cloud_shadow *= get_transmittance_to_sun(stratus_cloud_layer, world_pos);
}
