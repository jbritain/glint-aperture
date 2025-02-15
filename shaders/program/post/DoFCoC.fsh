#version 450 core

in vec2 uv;

#include "/lib/common.glsl"

float tentFilter(sampler2D sourceTexture, vec2 coord){
  vec2 offset = 0.5 / ap.game.screenSize;

  float usample = 0.0;
  usample += texture(sourceTexture, coord + offset * vec2(1.0)).r;
  usample += texture(sourceTexture, coord + offset * vec2(1.0, -1.0)).r;
  usample += texture(sourceTexture, coord + offset * vec2(-1.0)).r;
  usample += texture(sourceTexture, coord + offset * vec2(-1.0, 1.0)).r;

  usample /= 4.0;

  return usample;
}

layout(location = 0) out float CoC;

void main(){
  float depth = tentFilter(mainDepthTex, uv).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(uv, depth));
  float dist = viewPos.z;

  float focusDist = screenSpaceToViewSpace(texture(mainDepthTex, vec2(0.5)).r);
  CoC = clamp(1.0 - focusDist / dist, -1.0, 1.0);
}