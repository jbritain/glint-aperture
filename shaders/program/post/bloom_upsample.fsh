#version 460 core

#include "/lib/common.glsl"

in vec2 uv;

uniform sampler2D scene_tex;
uniform sampler2D bloom_tex;

vec3 up_sample(sampler2D source_texture, vec2 coord) {
  //  1   | 1 2 1 |
  // -- * | 2 4 2 |
  // 16   | 1 2 1 |

  vec2 res = rcp(textureSize(source_texture, BLOOM_INDEX));
  float x = res.x;
  float y = res.y;

  vec3 a = textureLod(
    source_texture,
    vec2(coord.x - x, coord.y + y),
    BLOOM_INDEX
  ).rgb;
  vec3 b = textureLod(
    source_texture,
    vec2(coord.x, coord.y + y),
    BLOOM_INDEX
  ).rgb;
  vec3 c = textureLod(
    source_texture,
    vec2(coord.x + x, coord.y + y),
    BLOOM_INDEX
  ).rgb;

  vec3 d = textureLod(
    source_texture,
    vec2(coord.x - x, coord.y),
    BLOOM_INDEX
  ).rgb;
  vec3 e = textureLod(source_texture, vec2(coord.x, coord.y), BLOOM_INDEX).rgb;
  vec3 f = textureLod(
    source_texture,
    vec2(coord.x + x, coord.y),
    BLOOM_INDEX
  ).rgb;

  vec3 g = textureLod(
    source_texture,
    vec2(coord.x - x, coord.y - y),
    BLOOM_INDEX
  ).rgb;
  vec3 h = textureLod(
    source_texture,
    vec2(coord.x, coord.y - y),
    BLOOM_INDEX
  ).rgb;
  vec3 i = textureLod(
    source_texture,
    vec2(coord.x + x, coord.y - y),
    BLOOM_INDEX
  ).rgb;

  vec3 usample = e * 4.0;
  usample += (b + d + f + h) * 2.0;
  usample += a + c + g + i;
  usample /= 16.0;

  return usample;
}

layout(location = 0) out vec3 bloom;

void main() {
  #if BLOOM_INDEX == 1
  bloom = texture(scene_tex, uv).rgb;

  #else
  bloom = textureLod(bloom_tex, uv, BLOOM_INDEX - 1).rgb;
  #endif

  bloom += up_sample(bloom_tex, uv);

}
