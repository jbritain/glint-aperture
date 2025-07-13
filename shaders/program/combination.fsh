#version 460 core

#include "/lib/common.glsl"

float luminance(vec3 color) {
  return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec3 jodieReinhardTonemap(vec3 v) {
  float l = luminance(v);
  vec3 tv = v / (1.0f + v);
  return pow(mix(v / (1.0f + l), tv, tv), vec3(rcp(2.2)));
}

vec3 apply_range(vec3 color, float min_val, float max_val) {
  return clamp((color - min_val) / (max_val - min_val), 0.0, 1.0);
}

uniform sampler2D final_color_tex;

layout(location = 0) out vec4 out_color;

in vec2 uv;

void main() {
  out_color.rgb = jodieReinhardTonemap(texture(final_color_tex, uv).rgb * 2e-5);
}
