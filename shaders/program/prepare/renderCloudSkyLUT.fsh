#version 450 core

#include "/lib/common.glsl"
#include "/lib/util/uvMap.glsl"

in vec2 uv;

#define HIGH_CLOUD_SAMPLES
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/clouds.glsl"

layout(location = 0) out vec3 sky;

void main(){
  vec3 dir = unmapSphere(uv);

  sky = getSky(vec3(0.0), dir, false);
  LightInteraction clouds = getClouds(dir, 1.0);
  sky = sky * clouds.transmittance + clouds.scattering;
}