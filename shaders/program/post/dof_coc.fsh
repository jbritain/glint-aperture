#version 460 core

in vec2 uv;

uniform sampler2D mainDepthTex;

#include "/lib/common.glsl"
#include "/lib/util/space_conversions.glsl"

float tent_filter(sampler2D source_texture, vec2 coord) {
  vec2 offset = 0.5 / textureSize(source_texture, 0).xy;

  float u_sample = 0.0;
  u_sample += texture(source_texture, coord + offset * vec2(1.0)).r;
  u_sample += texture(source_texture, coord + offset * vec2(1.0, -1.0)).r;
  u_sample += texture(source_texture, coord + offset * vec2(-1.0)).r;
  u_sample += texture(source_texture, coord + offset * vec2(-1.0, 1.0)).r;

  u_sample /= 4.0;

  return u_sample;
}

layout(location = 0) out float coc;

void main() {
  float depth = tent_filter(mainDepthTex, uv).r;
  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));
  float dist = view_pos.z;

  float focus_dist = screen_space_to_view_space(
    texture(mainDepthTex, vec2(0.5)).r
  );
  coc = clamp(1.0 - focus_dist / dist, -1.0, 1.0);

  if (any(isnan(coc)) || any(isinf(coc))) {
    coc = 0.0;
  }
}
