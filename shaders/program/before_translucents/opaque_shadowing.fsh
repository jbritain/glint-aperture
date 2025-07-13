#version 460 core

uniform sampler2DArrayShadow shadowMapFiltered;
uniform sampler2D shadowMap;

#include "/lib/common.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/buffers/scene_data.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/lighting/shadows.glsl"

in vec2 uv;

uniform sampler2D gbuffer_tex_1;

uniform sampler2D mainDepthTex;

layout(location = 0) out vec3 shadowing;
layout(location = 1) out vec3 subsurface_scattering;

void main() {
  float depth = texture(mainDepthTex, uv).r;
  if (depth == 1.0) {
    return;
  }

  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));
  vec3 player_pos = (ap.camera.viewInv * vec4(view_pos, 1.0)).xyz;

  Reduced_Gbuffer gbuffer = decode_reduced_gbuffer(texture(gbuffer_tex_1, uv));

  Shadow_Subsurface_Scatter result =
    compute_shadowing_and_subsurface_scattering(
      player_pos,
      mat3(ap.camera.viewInv) * gbuffer.geometry_normal,
      0.0
    );

  shadowing = result.shadow;
  subsurface_scattering = result.subsurface_scatter;

}
