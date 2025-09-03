#version 460 core

in vec2 uv;

uniform sampler2D dof_tex;
uniform sampler2D dof_coc_tex;
uniform sampler2D scene_tex;

#include "/lib/common.glsl"

layout(location = 0) out vec4 color;

vec3 tent_filter(sampler2D source_texture, vec2 coord) {
  vec2 offset = 0.5 / textureSize(source_texture, 0).xy;

  vec3 u_sample = vec3(0.0);
  u_sample += texture(source_texture, coord + offset * vec2(1.0)).rgb;
  u_sample += texture(source_texture, coord + offset * vec2(1.0, -1.0)).rgb;
  u_sample += texture(source_texture, coord + offset * vec2(-1.0)).rgb;
  u_sample += texture(source_texture, coord + offset * vec2(-1.0, 1.0)).rgb;

  u_sample /= 4.0;

  return u_sample;
}

void main() {
  vec3 dof = tent_filter(dof_tex, uv).rgb;

  float coc = texture(dof_coc_tex, uv).r;
  color = texture(scene_tex, uv);

  float dof_strength = smoothstep(0.1, 0.2, abs(coc));
  color.rgb = mix(color.rgb, dof.rgb, saturate(dof_strength));
}
