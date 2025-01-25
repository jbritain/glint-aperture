#version 450 core

#include "/lib/common.glsl"

in vec2 uv;

uniform sampler2D sceneTex;
uniform sampler2D solidDepthTex;
uniform sampler2D mainDepthTex;

layout(location = 0) out vec3 previousScene;
layout(location = 1) out vec2 previousDepth;

void main(){
  previousScene = texture(sceneTex, uv).rgb;
  previousDepth.r = texture(solidDepthTex, uv).r;
  previousDepth.g = texture(mainDepthTex, uv).r;
}