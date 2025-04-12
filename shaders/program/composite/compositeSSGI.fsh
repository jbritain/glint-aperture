#version 450 core

in vec2 uv;

uniform sampler2D gbufferDataTex1;
uniform sampler2D gbufferDataTex2;
uniform sampler2D sceneTex;
uniform sampler2D globalIlluminationTex;
uniform sampler2D solidDepthTex;

#include "/lib/common.glsl"

layout(location = 0) out vec3 color;

#define GI_SAMPLES 8

void main(){
  color = texture(sceneTex, uv).rgb;

  float depth = texture(solidDepthTex, uv).r;
  if(depth == 1.0){
    return;
  }

  GbufferData gbufferData;
  decodeGbufferData(texture(gbufferDataTex1, uv), texture(gbufferDataTex2, uv), gbufferData);

  color += textureLod(globalIlluminationTex, uv, 0).rgb * gbufferData.material.albedo;

  color += gbufferData.material.emission * gbufferData.material.albedo * 16.0;
}