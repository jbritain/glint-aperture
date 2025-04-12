#version 450 core

uniform sampler2D sceneTex;
uniform sampler2D mainDepthTex;
uniform sampler2D solidDepthTex;

#include "/lib/common.glsl"

in vec2 uv;

layout(location = 0) out vec3 previousScene;
layout(location = 1) out vec2 previousDepth;

void main(){
  vec3 color = texture(sceneTex, uv).rgb;

  if(any(isnan(color))){
    previousScene = vec3(1.0);
  } else {
    previousScene = color;
  }

  previousDepth.r = texture(mainDepthTex, uv).r;
  previousDepth.g = texture(solidDepthTex, uv).r;

}