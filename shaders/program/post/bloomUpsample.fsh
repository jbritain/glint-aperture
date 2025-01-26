#version 450 core

#include "/lib/common.glsl"

in vec2 uv;


vec3 upSample(sampler2D sourceTexture, vec2 coord){
    //  1   | 1 2 1 |
    // -- * | 2 4 2 |
    // 16   | 1 2 1 |

  float x = rcp(ap.game.screenSize.x / pow(2, BLOOM_INDEX));
  float y = rcp(ap.game.screenSize.y / pow(2, BLOOM_INDEX));

  vec3 a = textureLod(sourceTexture, vec2(coord.x - x, coord.y + y), BLOOM_INDEX).rgb;
  vec3 b = textureLod(sourceTexture, vec2(coord.x,     coord.y + y), BLOOM_INDEX).rgb;
  vec3 c = textureLod(sourceTexture, vec2(coord.x + x, coord.y + y), BLOOM_INDEX).rgb;

  vec3 d = textureLod(sourceTexture, vec2(coord.x - x, coord.y), BLOOM_INDEX).rgb;
  vec3 e = textureLod(sourceTexture, vec2(coord.x,     coord.y), BLOOM_INDEX).rgb;
  vec3 f = textureLod(sourceTexture, vec2(coord.x + x, coord.y), BLOOM_INDEX).rgb;

  vec3 g = textureLod(sourceTexture, vec2(coord.x - x, coord.y - y), BLOOM_INDEX).rgb;
  vec3 h = textureLod(sourceTexture, vec2(coord.x,     coord.y - y), BLOOM_INDEX).rgb;
  vec3 i = textureLod(sourceTexture, vec2(coord.x + x, coord.y - y), BLOOM_INDEX).rgb;

  vec3 usample = e*4.0;
  usample += (b + d + f + h) * 2.0;
  usample += (a + c + g + i);
  usample /= 16.0;

  return usample;
}

layout(location = 0) out vec3 bloomColor;

void main(){
  #if BLOOM_INDEX == 1
  bloomColor = texture(sceneTex, uv).rgb;
  #else
  bloomColor = textureLod(bloomTex, uv, BLOOM_INDEX - 1).rgb;
  #endif

  bloomColor += upSample(bloomTex, uv);
}