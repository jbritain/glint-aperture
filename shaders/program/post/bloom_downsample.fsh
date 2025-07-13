#version 460 core

#include "/lib/common.glsl"

in vec2 uv;

uniform sampler2D scene_tex;
uniform sampler2D bloom_tex;

vec3 down_sample(sampler2D source_texture, vec2 coord) {
  // a - b - c
  // - j - k -
  // d - e - f
  // - l - m -
  // g - h - i

  vec2 res = rcp(textureSize(source_texture, BLOOM_INDEX));
  float x = res.x;
  float y = res.y;

  vec3 a = textureLod(
    source_texture,
    vec2(coord.x - 2 * x, coord.y + 2 * y),
    BLOOM_INDEX
  ).rgb;
  vec3 b = textureLod(
    source_texture,
    vec2(coord.x, coord.y + 2 * y),
    BLOOM_INDEX
  ).rgb;
  vec3 c = textureLod(
    source_texture,
    vec2(coord.x + 2 * x, coord.y + 2 * y),
    BLOOM_INDEX
  ).rgb;
  vec3 d = textureLod(
    source_texture,
    vec2(coord.x - 2 * x, coord.y),
    BLOOM_INDEX
  ).rgb;
  vec3 e = textureLod(source_texture, vec2(coord.x, coord.y), BLOOM_INDEX).rgb;
  vec3 f = textureLod(
    source_texture,
    vec2(coord.x + 2 * x, coord.y),
    BLOOM_INDEX
  ).rgb;
  vec3 g = textureLod(
    source_texture,
    vec2(coord.x - 2 * x, coord.y - 2 * y),
    BLOOM_INDEX
  ).rgb;
  vec3 h = textureLod(
    source_texture,
    vec2(coord.x, coord.y - 2 * y),
    BLOOM_INDEX
  ).rgb;
  vec3 i = textureLod(
    source_texture,
    vec2(coord.x + 2 * x, coord.y - 2 * y),
    BLOOM_INDEX
  ).rgb;
  vec3 j = textureLod(
    source_texture,
    vec2(coord.x - x, coord.y + y),
    BLOOM_INDEX
  ).rgb;
  vec3 k = textureLod(
    source_texture,
    vec2(coord.x + x, coord.y + y),
    BLOOM_INDEX
  ).rgb;
  vec3 l = textureLod(
    source_texture,
    vec2(coord.x - x, coord.y - y),
    BLOOM_INDEX
  ).rgb;
  vec3 m = textureLod(
    source_texture,
    vec2(coord.x + x, coord.y - y),
    BLOOM_INDEX
  ).rgb;

  vec3 d_sample;
  d_sample = e * 0.125;
  d_sample += (a + c + g + i) * 0.03125;
  d_sample += (b + d + f + h) * 0.0625;
  d_sample += (j + k + l + m) * 0.125;

  d_sample = max(d_sample, 0.0001);

  return d_sample;
}

layout(location = 0) out vec3 bloom;

void main() {
  if (BLOOM_INDEX == 0) {
    bloom = down_sample(scene_tex, uv);
  } else {
    bloom = down_sample(bloom_tex, uv);
  }
}
