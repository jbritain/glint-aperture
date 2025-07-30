#version 460 core

uniform sampler2DArrayShadow shadowMapFiltered;
uniform sampler2DArray shadowMap;

#include "/lib/common.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/buffers/scene_data.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/subsurface_scattering.glsl"

in vec2 uv;

uniform sampler2D gbuffer_tex_1;

uniform sampler2D mainDepthTex;

layout(location = 0) out vec4 shadowing_and_blocker_distance;

void main() {
  float depth = texture(mainDepthTex, uv).r;
  if (depth == 1.0) {
    return;
  }

  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));
  vec3 player_pos = (ap.camera.viewInv * vec4(view_pos, 1.0)).xyz;

  Reduced_Gbuffer gbuffer = decode_reduced_gbuffer(texture(gbuffer_tex_1, uv));

  shadowing_and_blocker_distance = compute_shadowing_and_blocker_distance(
    player_pos,
    gbuffer.geometry_normal
  );

}
