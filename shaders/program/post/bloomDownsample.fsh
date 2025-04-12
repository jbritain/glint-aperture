#version 450 core

#include "/lib/common.glsl"

in vec2 uv;

uniform sampler2D sceneTex;
uniform sampler2D bloomTex;

vec3 downSample(sampler2D sourceTexture, vec2 coord){
    // a - b - c
    // - j - k -
    // d - e - f
    // - l - m -
    // g - h - i

  float x = 1.0 / float(ap.game.screenSize.x / pow(2, BLOOM_INDEX));
  float y = 1.0 / float(ap.game.screenSize.y / pow(2, BLOOM_INDEX));

  vec3 a = textureLod(sourceTexture, vec2(coord.x - 2*x, coord.y + 2*y), BLOOM_INDEX).rgb;
  vec3 b = textureLod(sourceTexture, vec2(coord.x,       coord.y + 2*y), BLOOM_INDEX).rgb;
  vec3 c = textureLod(sourceTexture, vec2(coord.x + 2*x, coord.y + 2*y), BLOOM_INDEX).rgb;
  vec3 d = textureLod(sourceTexture, vec2(coord.x - 2*x, coord.y), BLOOM_INDEX).rgb;
  vec3 e = textureLod(sourceTexture, vec2(coord.x,       coord.y), BLOOM_INDEX).rgb;
  vec3 f = textureLod(sourceTexture, vec2(coord.x + 2*x, coord.y), BLOOM_INDEX).rgb;
  vec3 g = textureLod(sourceTexture, vec2(coord.x - 2*x, coord.y - 2*y), BLOOM_INDEX).rgb;
  vec3 h = textureLod(sourceTexture, vec2(coord.x,       coord.y - 2*y), BLOOM_INDEX).rgb;
  vec3 i = textureLod(sourceTexture, vec2(coord.x + 2*x, coord.y - 2*y), BLOOM_INDEX).rgb;
  vec3 j = textureLod(sourceTexture, vec2(coord.x - x, coord.y + y), BLOOM_INDEX).rgb;
  vec3 k = textureLod(sourceTexture, vec2(coord.x + x, coord.y + y), BLOOM_INDEX).rgb;
  vec3 l = textureLod(sourceTexture, vec2(coord.x - x, coord.y - y), BLOOM_INDEX).rgb;
  vec3 m = textureLod(sourceTexture, vec2(coord.x + x, coord.y - y), BLOOM_INDEX).rgb;

  vec3 dsample;
  dsample = e * 0.125;
  dsample += (a+c+g+i) * 0.03125;
  dsample += (b+d+f+h) * 0.0625;
  dsample += (j+k+l+m) * 0.125;

  dsample = max(dsample, 0.0001);

  return dsample;
}

layout(location = 0) out vec3 bloomColor;

void main(){
  if(BLOOM_INDEX == 0){
    bloomColor = downSample(sceneTex, uv);
  } else {
    bloomColor = downSample(bloomTex, uv);
  }
}