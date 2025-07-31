#version 460 core

#include "/lib/common.glsl"
#include "/lib/post/tonemap.glsl"

vec3 apply_range(vec3 color, float min_val, float max_val) {
  return clamp((color - min_val) / (max_val - min_val), 0.0, 1.0);
}

uniform sampler2D scene_tex;
uniform sampler2D bloom_tex;
uniform sampler2D debug_tex;

layout(location = 0) out vec3 color;

in vec2 uv;

void main() {
  color = texture(scene_tex, uv).rgb;

  vec3 bloom = texture(bloom_tex, uv).rgb;
  color = mix(color, bloom, 0.01);
  color = tonemap(color);

  // color = texture(debug_tex, uv).rgb;

}
