#version 450 core

#define SKY_SAMPLERS
#define CLOUD_NOISE_SAMPLERS

#include "/lib/common.glsl"
#include "/lib/util/uvMap.glsl"

in vec2 uv;

#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/clouds.glsl"

layout(location = 0) out vec3 sky;

void main(){
  vec3 oldSky = texture(cloudSkyLUTTex, uv).rgb;

  vec3 dir = unmapSphere(uv);

  sky = getSky(vec3(0.0), dir, false);
  LightInteraction clouds = getClouds(dir, 1.0);
  sky = sky * clouds.transmittance + clouds.scattering;
  sky = mix(oldSky, sky, 0.01);
}